import { useCurrency } from "../hooks/Tokens"
import { useTradeExactIn, useTradeExactOut } from "../hooks/Trades"
import { tryParseAmount } from "../state/swap/hooks"

export default function CreateV2SwapTrade(inputCurrencyId: string, outputCurrencyId: string, typedValue: string) {
    const inputCurrency = useCurrency(inputCurrencyId)
    const outputCurrency = useCurrency(outputCurrencyId)

    const isExactIn = true;
    const parsedAmount = tryParseAmount(typedValue, (isExactIn ? inputCurrency : outputCurrency) ?? undefined)
  
    const bestTradeExactIn = useTradeExactIn(isExactIn ? parsedAmount : undefined, outputCurrency ?? undefined)
    const bestTradeExactOut = useTradeExactOut(inputCurrency ?? undefined, !isExactIn ? parsedAmount : undefined)
  
    return isExactIn ? bestTradeExactIn : bestTradeExactOut

}