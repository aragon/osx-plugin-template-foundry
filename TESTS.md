# Test tree definitions

Below is the graphical summary of the tests described within [test/*.t.yaml](./test)

```
MyPluginTest
├── Given The plugin is already initialized
│   ├── When Calling initialize
│   │   └── It Should revert
│   └── When Calling dao and number
│       └── It Should return the right values
├── Given The caller has no permission // The caller needs MANAGER_PERMISSION_ID
│   └── When Calling setNumber
│       └── It Should revert
├── Given The caller has permission // The caller holds MANAGER_PERMISSION_ID
│   └── When Calling setNumber 2
│       └── It Should update the stored number
└── When Calling number
    └── It Should return the right value
```
