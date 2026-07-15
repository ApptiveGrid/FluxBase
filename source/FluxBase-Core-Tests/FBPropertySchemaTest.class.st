Class {
	#name : 'FBPropertySchemaTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBPropertySchemaTest >> testAtPutAndAt [
	| schema |
	schema := FBPropertySchema new.
	schema at: #age put: FBPropertyType number.
	self assert: (schema at: #age) class equals: FBPropertyNumberType
]

{ #category : 'tests' }
FBPropertySchemaTest >> testKeysReturnsAllDefinedKeys [
	| schema |
	schema := FBPropertySchema new.
	schema at: #age put: FBPropertyType number.
	schema at: #name put: FBPropertyType string.
	self assert: schema keys asSet equals: #(age name) asSet
]

{ #category : 'tests' }
FBPropertySchemaTest >> testAtIfPresentIfAbsent [
	| schema |
	schema := FBPropertySchema new.
	schema at: #age put: FBPropertyType number.
	self assert: (schema at: #age ifPresent: [ :t | t class ] ifAbsent: [ 'nope' ]) equals: FBPropertyNumberType.
	self assert: (schema at: #missing ifPresent: [ :t | t class ] ifAbsent: [ 'nope' ]) equals: 'nope'
]
