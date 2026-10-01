# Simple MT5 Scalper EA

This project contains a simple Expert Advisor (EA) for MetaTrader 5 designed for a basic forex scalping strategy on:

- EURUSD
- XAUUSD (Gold)

It is intended as a starting point for learning and testing in a demo account before using any real funds.

## Included files

- `SimpleScalperEA.mq5` — the MT5 Expert Advisor source code

## Features

- Start/stop toggle via button on the chart
- Trades EURUSD and XAUUSD
- Uses a basic MA + RSI momentum strategy
- One trade per symbol at a time
- Stop loss and take profit
- Optional trailing stop
- Magic number support for position tracking
- Risk controls using fixed lot size

## Important notes

- This is an educational trading robot, not a guaranteed profit system.
- Do not use it on a live account without testing thoroughly on a demo account.
- The default strategy is intentionally simple and may require optimization for your broker, spread, and market conditions.
- The robot uses fixed lot sizing. Adjust `LotSize` to suit your account.

## Recommended setup

- Pair: EURUSD and XAUUSD
- Timeframe: M5
- Broker: MT5 demo account
- Use low spread conditions

## How to use in MT5

1. Open MetaEditor in MT5.
2. Create a new Expert Advisor file.
3. Copy the contents of `SimpleScalperEA.mq5` into the file.
4. Compile the EA.
5. Attach the EA to a EURUSD or XAUUSD chart.
6. Enable live trading.
7. Click the "START/STOP" button on the chart to toggle the robot.

## Inputs you can adjust

- `EnableEA` — enable or disable trading
- `LotSize` — risk per trade
- `StopLossPoints` — stop distance
- `TakeProfitPoints` — profit target
- `FastMAPeriod` — fast moving average
- `SlowMAPeriod` — slow moving average
- `RSIPeriod` — RSI period
- `MaxSpreadPoints` — maximum allowed spread before skipping trades
- `UseTrailingStop` — enable or disable trailing
- `TrailingStopPoints` — trailing stop distance

## Risk warning

Trading forex and gold carries risk. This EA is only a template. Past performance does not guarantee future results.

## Disclaimer

This project is provided for educational and testing purposes only. It is not financial advice.
