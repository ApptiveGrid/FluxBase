Class {
	#name : 'FBPropertiesTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBPropertiesTest >> testAtIfAbsentReturnsBlockValueWhenMissing [
	| props |
	props := FBProperties new.
	self assert: (props at: #missing ifAbsent: [ 42 ]) equals: 42
]

{ #category : 'tests' }
FBPropertiesTest >> testAtIfPresentCallsBlockWithValue [
	| props seen |
	props := FBProperties new.
	props at: #x put: 5.
	seen := props at: #x ifPresent: [ :v | v * 2 ].
	self assert: seen equals: 10
]

{ #category : 'tests' }
FBPropertiesTest >> testAtPutAndAt [
	| props |
	props := FBProperties new.
	props at: #name put: 'Ada'.
	self assert: (props at: #name) equals: 'Ada'
]

{ #category : 'tests' }
FBPropertiesTest >> testAtPutAppliesSchemaTypeRead [
	| props schema |
	schema := FBPropertySchema new.
	schema at: #name put: FBPropertyType string.
	props := FBProperties new.
	props schema: schema.
	props at: #name put: 42.
	self assert: (props at: #name) equals: '42'
]

{ #category : 'tests' }
FBPropertiesTest >> testAtPutWithoutSchemaEntryKeepsRawValue [
	| props schema |
	schema := FBPropertySchema new.
	schema at: #name put: FBPropertyType string.
	props := FBProperties new.
	props schema: schema.
	props at: #other put: 42.
	self assert: (props at: #other) equals: 42
]

{ #category : 'tests' }
FBPropertiesTest >> testKeysAndValuesDoIteratesAllEntries [
	| props seen |
	props := FBProperties new.
	props at: #a put: 1.
	props at: #b put: 2.
	seen := Dictionary new.
	props keysAndValuesDo: [ :k :v | seen at: k put: v ].
	self assert: (seen at: #a) equals: 1.
	self assert: (seen at: #b) equals: 2
]
