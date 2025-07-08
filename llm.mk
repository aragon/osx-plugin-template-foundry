define TEST_TREE_GENERATION_PROMPT
You are an extremely meticulous testing engineer, know for identifying every possible scenario and edge case.
You are also known for being able to craft very logical and well structured hierarchies to define test suites.

I am describing all the testing hierarchy of a smart contract using a yaml file with the following structure:

```yaml
MyPluginTest:
  - given: The plugin is already initialized
    and:
      - when: Calling initialize()
        then:
          - it: Should revert
      - when: Calling dao() and number()
        then:
          - it: Should return the right values
  - given: The caller has no permission
    comment: The caller needs MANAGER_PERMISSION_ID
    and:
      - when: Calling setNumber()
        then:
          - it: Should revert
  - given: The caller has permission
    comment: The caller holds MANAGER_PERMISSION_ID
    and:
      - when: Calling setNumber()
        then:
          - it: Should update the stored number
  - when: Calling number()
    then:
      - it: Should return the right value
```

The only supported yaml nodes in this schema are `when`, `given`, `it`, `and`, `then`, `comment`.
The only supported cases are:

```yaml
- given: (existing state or context)
  then:
    - it: (expected predicate)
```

```yaml
- when: (event or action)
  then:
    - it: (expected predicate)
```

```yaml
- given: (existing state or context)
  and:
    (a nested object)
```

```yaml
- when: (event or action)
    and:
    (a nested object)
```

- `when` and `given` are mutually exclusive. The should contain brief string.
- `comment` is entirely optional. Only allowed in `when` or `given` nodes. It should never appear after `then`.
- The name of the root node should contain a name that conveys what the contract is (i.e: `TokenVotingPluginTest`)

Now look at the source file (below) and generate an accurate and exhaustive test definition file in yaml using the structure you saw above.
The structure should cover absolutely all the scenarios and edge cases arising from the source file below, as well as any scenario from the external components that might interact with it.

Warning: Yaml fields with inner quotes like `comment: Creating DAO's` or `- it: Should do "this" and "that"` or `- comment: The 'auth(MANAGER_PERMISSION_ID)' modifier should fail` will break the yaml parser, because of an invalid syntax. In these cases you must wrap the whole string with external quotes to produce a valid yaml.

The source file for which the test definition needs to be done:

```solidity
<<SOURCE_FILE>>
```
endef

define TEST_FILE_GENERATION_PROMPT
You are a senior smart contract testing engineer, know for his extreme accuracy and his finely written test code.

I want you to implement the tests of a solidity contract on Foundry.
I want you to use the following codebase as the reference for ABI's, contract definition, structs, data types and so on.

```solidity
<<SOURCE>>
```

I also want you to use this builder contract as a resource, which allows you to very easily prepare throwaway deployments with sane defaults that can be overriden if needed:
Use it when writing tests that require a certain setup to keep things readable and repeatable.

```solidity
<<DAO_BUILDER>>
```

I also want you to be aware of this base contract, that all test contracts must inherit from and use:

```solidity
<<TEST_BASE>>
```

You must use the test definition below as your main script for the test implementation:

```yaml
<<TEST_TREE>>
```

Finally, use all the above context and implement the tests on following solidity test file.
- Try to write them within the corresponding function placeholders and modifiers, when possible
- Try to use the existing modifiers along with the builder, to prepare scenarios shared by several test functions.
- Add any additional tests that you deem necessary.
- Keep modifiers at the original place, near where they are consumed.
- Use the builder as an external resource, do not inherit from it.

```solidity
<<TARGET_TEST_FILE>>
```

Generate the test file, given all the above.
endef
