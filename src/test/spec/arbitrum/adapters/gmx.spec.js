const { expect } = require("chai")
const { ethers, deployments } = require("hardhat")
const { parseUnits } = ethers.utils
const { deploy } = deployments


const { helpers, addresses } = require('../../../fixtures')
const { 
    getSupportedERC20Tokens,
    forkGlobalNetwork, 
    makeAccountGen,
    setERC20Bal, 
} = helpers
const { gmx } = addresses.arbitrum

async function getEnv(forkBlockNumber) {
    await forkGlobalNetwork(forkBlockNumber, 'arbitrum')
    const [ deployer ] = await ethers.getSigners()
    const adapterArgs = [
        'GmxAdapter', gmx.vault, 630_000,
    ]
    const Adapter = await ethers.getContractFactory("GmxAdapter")
        .then(f => f.connect(deployer).connect(deployer).deploy(...adapterArgs))
    return {
        Adapter,
        deployer
    }
}

describe('YakAdapter - Gmx', function() {
    

    async function checkAdapterSwapMatchesQuery(
        tokenFrom, 
        tokenTo, 
        amountInFixed
    ) {
        amountIn = parseUnits(amountInFixed, await tokenFrom.decimals())
        // Querying adapter 
        const amountOutQuery = await Adapter.query(
            amountIn, 
            tokenFrom.address, 
            tokenTo.address
        )
        // Mint tokens to adapter address
        await setERC20Bal(tokenFrom.address, Adapter.address, amountIn)
        expect(amountOutQuery).to.gt(0)
        // Swapping
        const swap = () => Adapter.connect(trader).swap(
            amountIn, 
            amountOutQuery,
            tokenFrom.address,
            tokenTo.address, 
            trader.address
        )
        // Check that swap matches the query and nothing is left in the adapter
        await expect(swap).to.changeTokenBalances(
            tokenTo, 
            [trader, Adapter], 
            [amountOutQuery, parseUnits('0')]
        )
    }

    async function checkGasCost(options) {
        let maxGas = 0
        for (let [ tokenFrom, tokenTo, amountIn ] of options) {
            // Mint tokens to adapter address
            await setERC20Bal(tokenFrom.address, Adapter.address, amountIn)
            // Querying
            const queryTx = await Adapter.populateTransaction.query(
                amountIn, 
                tokenFrom.address, 
                tokenTo.address
            )
            const queryGas = await ethers.provider.estimateGas(queryTx)
                .then(parseInt)
            const quote = await Adapter.query(
                amountIn, 
                tokenFrom.address, 
                tokenTo.address
            )
            // Swapping
            const swapGas = await Adapter.connect(trader).swap(
                amountIn, 
                quote,
                tokenFrom.address,
                tokenTo.address, 
                trader.address
            ).then(tr => tr.wait()).then(r => parseInt(r.gasUsed))
            console.log(`swap-gas:${swapGas} | query-gas:${queryGas}`)
            const gasUsed = swapGas + queryGas
            if (gasUsed > maxGas) {
                maxGas = gasUsed
            }
        }
        // Check that gas estimate is above max, but below 10% of max
        const estimatedGas = await Adapter.swapGasEstimate().then(parseInt)
        expect(estimatedGas).to.be.within(maxGas, maxGas * 1.1)
    }

    let genNewAccount
    let adapterOwner
    let Adapter
    let trader
    let tkns

    before(async () => {
        const forkBlockNumber = 16485220
        const env_ = await getEnv(forkBlockNumber)
        adapterOwner = env_.deployer
        Adapter = env_.Adapter
        tkns = await getSupportedERC20Tokens('arbitrum')
        genNewAccount = await makeAccountGen()
    })

    beforeEach(async () => {
        trader = genNewAccount()
    })

    describe('Swapping matches query', async () => {

        it('USDC -> WETH', async () => {
            await checkAdapterSwapMatchesQuery(tkns.USDC, tkns.WETH, '100')
        })
        it('FRAX -> UNI', async () => {
            await checkAdapterSwapMatchesQuery(tkns.FRAX, tkns.UNI, '100')
        })
        it('DAI -> WBTC', async () => {
            await checkAdapterSwapMatchesQuery(tkns.DAI, tkns.WBTC, '100')
        })

    })

    it('Query returns zero if tokens not found', async () => {
        const tokenFrom = tkns.USDC
        const tokenTo = ethers.constants.AddressZero
        const amountIn = parseUnits('1', 6)
        const amountOutQuery = await Adapter.query(
            amountIn, 
            tokenFrom.address, 
            tokenTo
        )
        expect(amountOutQuery).to.eq(0)
    })

    it('Gas-estimate is within limits', async () => {
        const options = [
            [ tkns.USDC, tkns.DAI, parseUnits('1', 6) ],
            [ tkns.DAI, tkns.WETH, parseUnits('1', 6) ], 
            [ tkns.FRAX, tkns.UNI, parseUnits('1', 18) ],
        ]
        await checkGasCost(options)
    })

})