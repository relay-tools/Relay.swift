# ``Relay/RecordProxy``

## Topics

### Reading record metadata

- ``dataID``
- ``typeName``

### Accessing fields from a record

- ``subscript(_:)``
- ``subscript(_:args:)``

### Accessing linked records

- ``getLinkedRecord(_:)``
- ``getLinkedRecord(_:args:)``
- ``setLinkedRecord(_:record:)``
- ``setLinkedRecord(_:args:record:)``
- ``getOrCreateLinkedRecord(_:typeName:)``
- ``getOrCreateLinkedRecord(_:typeName:args:)``

### Accessing lists of linked records

- ``getLinkedRecords(_:)``
- ``getLinkedRecords(_:args:)``
- ``setLinkedRecords(_:records:)``
- ``setLinkedRecords(_:args:records:)``

### Copying between records

- ``copyFields(from:)``

### Invalidation

- ``invalidateRecord()``
