# Belongings, work payments and Haverlund Savings

Implemented first slice, 2026-11-02. **I** or **Bag** opens carried tools, reusable stock, purse, bank balance and recent transactions. **F** at Haverlund Savings' existing street counter in Rootward Square opens deposits and withdrawals. All values are whole pence; transfers have no fees or interest.

| Completed job | Payment |
|---|---:|
| Stair light (`landing-light`) | 6 p |
| Morning round (`morning-round`) | 12 p |
| A proper welcome (`proper-welcome`) | 25 p |

Amounts are authored in `content/journeys/sparks-and-machines.json: payments`. The game settles each completed job once, recording a receipt under its stable quest ID. Older saves receive these wages once when resumed. Reading a ticket and greeting Hotaru are unpaid. Iona also gives one reusable message card when her commission conversation finishes. Rewriting the sign does not consume it or award another wage.

`core/player_accounts.gd` owns plain-data rules for receipts, grants/removals, whole-pence transfers and atomic purchases. Currency balances cap at 9,999,999 p and known stock stacks at 99. Invalid amounts, unknown items, insufficient stock/money and overflow reject without mutation. Purchase rules are a foundation for later authored exchanges; no shop interface is implemented.

`GameSession.accounts` is journey property outside undoable world state:

```json
{"version":1,"wallet":43,"bank":0,"inventory":{"message-card":1},
 "receipts":{"landing-light":6,"morning-round":12,"proper-welcome":25,"welcome-material":0},
 "journal":[]}
```

The journal retains the latest 32 entries. Existing unique tools remain in `state.items`; the bag displays them alongside stackable stock rather than creating a second authority for Nell's slate. Save restoration bounds balances, filters unknown stock and restores receipts. Ordinary old saves without accounts start with an empty ledger before eligible wages are settled.

The active ledger replaces cached room ledgers during travel. It is never added to an old balance or merged by taking the largest balance. Program Undo/Reset only restores devices; it cannot reverse a bank transfer, refund an item or pay a completed job twice. Player Python has no money, inventory, purchase or bank-writing capability yet. Future puzzles should add explicit validated commands and authored prices/material requirements before exposing those capabilities.

Implemented: carried tools/stock, one-time wages, saving, account history, deposit/withdrawal and reusable exchange rules. Deferred: shops, house purchases/furnishing costs, item art/grids, passive income, interest, trading and a banking lesson. No combat or equipment statistics are introduced.

Proof: `test/test_accounts.gd`, `test/test_welcome_flow.gd` and the [outdoor quest review](reviews/2026-11-02-welcome-quest-and-property.md).
