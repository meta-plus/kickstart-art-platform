# TypeChain x Truffle v5 example

## Running

```sh
yarn # it will automatically run TypeChain types generation

# yarn generate-types to manually regenerate them
yarn postinstall

# run tests
truffle test

# migrations are kinda tricky (look at known limitation section) - we need to transpile ts to js file (this is not a case for tests)
yarn migrate
```


## Code Ownership
```
Copyright © 2022 PHOENNOVATION LIMITED. All rights reserved
```