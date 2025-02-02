# ⏳ DaVinciGraph Token Vesting V2

<div align="center">
  <img src="DAVINCI.png" alt="DaVinciGraph Logo" width="200"/>
  <h3>Release Tokens Over Time on Hedera</h3>
  <p>Contract ID: <a href="https://hashscan.io/mainnet/contract/0.0.8215498">0.0.8215498</a></p>
</div>

## 🎯 What is Token Vesting?

A system to release tokens gradually over time. Instead of giving all tokens at once, they are released bit by bit on a schedule. Perfect for team tokens, investor allocations, or any situation where you want controlled token distribution!

## 🎮 How to Use It?

1. **Initial Setup**

   - Choose your token or HBAR
   - Set total amount of tokens
   - Choose how many cycles (1-250)
   - Set how long each cycle is
   - Optional: Add cliff period
   - Choose who gets them (you or someone else)

2. **Initial Token Release**

   - Optional cliff period for early release
   - Get up to 95% tokens early
   - Must wait through cliff period
   - Perfect for team/investor initial allocations

3. **Regular Releases**
   - Remaining tokens release every cycle
   - Equal amounts each cycle
   - Continues until all tokens released

## 🕒 What is a Cliff Period?

A cliff is a waiting period before any tokens can be claimed. Think of it like a probation period at a new job!

**Simple Example:**

- You get 1000 tokens over 10 months
- With a 2-month cliff
- After 2 months: Get your first tokens
- Before 2 months: Can't claim anything

**Real World Examples:**

1. **Employee Tokens** (1-Year Cliff)

   ```
   Month 0-11: 🔒 No tokens (cliff period)
   Month 12:   ✨ Get 20% (200 tokens)
   Month 13-24: 💫 Get remaining 800 tokens (66.6 tokens monthly)
   ```

2. **Investor Tokens** (3-Month Cliff)
   ```
   Month 0-2:  🔒 No tokens (cliff period)
   Month 3:    ✨ Get 10% (100 tokens)
   Month 4-12: 💫 Get remaining 900 tokens (100 tokens monthly)
   ```

The cliff helps ensure long-term commitment - like waiting to earn your first paycheck at a new job!

## ⚙️ Schedule Options

- **Cycle Length**: 1 hour to 10 years
- **Number of Cycles**: 1 to 250 cycles
- **Cliff Period**: Optional 1 hour to 10 years wait
- **Initial Release**: Up to 95% of total tokens

💡 **Pro Tip**: You can create up to 50 vesting schedules at once - perfect for setting up your entire team or investor group in one go!

## 💰 Fees

- All fees are paid in DAVINCI tokens
- Maximum fee: 200 DAVINCI
- Fee structure:
  - Creating Schedule: 200 DAVINCI
  - Withdrawing Tokens: 20 DAVINCI
  - Multiple Schedules: 200 DAVINCI per schedule
- No fees for:
  - Withdrawing unlocked tokens
  - Checking lock information
  - Token association operations
- Some accounts can be fee-exempt

## ✅ Supported Tokens

- HBAR
- Any standard fungible Hedera token

## ❌ Not Supported

- NFTs
- Tokens with custom fees

## 👥 Who's Who?

- **Creator**: Person who sets up the vesting schedule
- **Beneficiary**: Person who receives and withdraws tokens

## ⚠️ Remember!

1. Can't change after creation
2. Each schedule is independent
3. Up to 50 schedules at once
4. HBAR and tokens both supported
5. Anyone can trigger the withdrawal
6. Only the beneficiary account will receive the tokens

## 🤝 Need Help?

- Visit [DaVinciGraph](https://davincigraph.io)
- Join [Discord](https://discord.gg/dGvkBmQGt9)
- Follow us on [X](https://x.com/davincigraph)

<div align="center">
  <p>Built with ❤️ by DaVinciGraph</p>
</div>
