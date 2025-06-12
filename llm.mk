define TEST_TREE_GENERATION_PROMPT
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
- given: (existing state)
  then:
    - it: (predicate)
```

```yaml
- when: (event or action)
  then:
    - it: (predicate)
```

```yaml
- when: (event or action)
  and:
    (another node)
```

```yaml
- given: (existing state)
  and:
    (another node)
```

`comment` is optional, and allowed in all nodes.
`describe` is not supported.

Now look at the existing source file (below) and generate an accurate and exhaustive test definition file in yaml using the structure you saw above.
The structure should cover absolutely all the cases, scenarios and edge cases from the source file below.

The source file for which the tests need to be defined:
endef
