Class {
	#name : 'FBNodeTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBNodeTest >> testNewNodeHasId [
	| node |
	node := FBNode new.
	self assert: (node id isKindOf: String).
	self assert: node id notEmpty
]

{ #category : 'tests' }
FBNodeTest >> testNodePropertiesDefined [
	| node schema |
	node := FBTestTaskWithBehavior  new.
	schema := node propertySchema.
	self assert: schema class equals: FBPropertySchema.
	self assert: schema keys size equals: 2.
]

{ #category : 'tests' }
FBNodeTest >> testNodePropertiesUndefined [
	| node schema |
	node := FBTestTask new.
	schema := node propertySchema.
	self assert: schema class equals: FBPropertySchema.
	self assert: schema keys size equals: 0
]

{ #category : 'tests' }
FBNodeTest >> testNodeSetProperty [
	| node |
	node := FBTestTaskWithBehavior  new.
	node propertyAt: #name put: 'Hello World'.
	self assert: (node propertyAt: #name) equals: 'Hello World'
]

{ #category : 'tests' }
FBNodeTest >> testTaskIsAbstractOnlyForTheBaseClass [
	self assert: FBTask isAbstract.
	self deny: AGSendEmailTask isAbstract.
	self assert: FBParallelNode isAbstract.
	self assert: FBParallelJoinNode isAbstract.
	self assert: FBPluggableTask isAbstract
]

{ #category : 'tests' }
FBNodeTest >> testWaitIsAbstractOnlyForTheBaseClass [
	self assert: FBWait isAbstract.
	self assert: FBWaitForCondition isAbstract.
	self assert: FBPluggableWait isAbstract
]
