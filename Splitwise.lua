-- Inofficial Splitwise Extension (www.splitwise.com) for MoneyMoney
-- Fetches balances from Splitwise API and returns them as securities
--
-- Username: Splitwise API Bearer Token
-- Password: Whatever you want it to be
--
-- Copyright (c) 2022 Sebastian Lauber
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

WebBanking{version     = "3.0",
           url         = "https://secure.splitwise.com/api",
           services    = {"Splitwise"},
           description = "Splitwise Balances"}

function SupportsBank (protocol, bankCode)
  return protocol == ProtocolWebBanking and bankCode == "Splitwise"
end

local accountNumber
local owner
local bearer

function InitializeSession (protocol, bankCode, username, reserved, password)
  -- stores the bearer token and fetches user information
  bearer = username
  local user = AuthorizedRequest("GET", "get_current_user", "user")
  accountNumber = string.format("%s (%s)", user["email"], user["id"])
  owner = string.format("%s %s", GetEmptyStringIfNil(user["first_name"]), GetEmptyStringIfNil(user["last_name"]))
end

function ListAccounts (knownAccounts)
  -- returns an array of accounts.
  local account = {
    name = "Splitwise Account",
    type = "AccountTypePortfolio",
    portfolio = true,
    owner = owner,
    accountNumber = accountNumber
  }
  return {account}
end

function AuthorizedRequest (method, endpoint, dictRoot)
  -- returns a Lua list from the authenticated http request
  local url = string.format("%s/v%s/%s", url, version, endpoint)
  local headers = {
    Authorization = string.format("Bearer %s", bearer)
  }  
  local connection = Connection()
  local content = connection:request(method, url, nil, nil, headers)
  if dictRoot then
    return JSON(content):dictionary()[dictRoot]
  else
    return JSON(content):dictionary()
  end
end

function RefreshAccount (account, since)
  local friends = AuthorizedRequest("GET", "get_friends", "friends")
  local securities = {}
  -- iterate over your friends
  for i,friend in ipairs(friends)
  do 
    -- iterate over the balances (which hold the balances by currency)
    for j,currency in ipairs(friend["balance"])
      do table.insert(securities,
        {
          -- format the amount
          name=string.format("%s %s", friend["first_name"], GetEmptyStringIfNil(friend["last_name"])),
          currency=currency["currency_code"],
          amount=currency["amount"]
        }
      )
    end
  end

  return {securities=securities}
end

function EndSession ()
  -- Logout.
end

-- Helper function
function GetEmptyStringIfNil(s)
  if s == nil then return ''
  else return s
  end
end