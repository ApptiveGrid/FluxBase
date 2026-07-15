Class {
	#name : 'FBSplitGatewayTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBSplitGatewayTest >> testCannotHaveMoreThanOneIncomingTransition [
	| gateway a b |
	gateway := FBExclusiveGateway named: 'g'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	a --> gateway.
	self
		should: [ b --> gateway ]
		raise: FBCannotAddTransition
]

{ #category : 'tests' }
FBSplitGatewayTest >> testExclusiveGatewayIsAKindOfSplitGateway [
	self assert: (FBExclusiveGateway inheritsFrom: FBSplitGateway)
]

{ #category : 'tests' }
FBSplitGatewayTest >> testMultiChoiceGatewayIsAKindOfSplitGateway [
	self assert: (FBMultiChoiceGateway inheritsFrom: FBSplitGateway)
]

{ #category : 'tests' }
FBSplitGatewayTest >> testSplitGatewayIsAbstractOnlyForTheBaseClass [
	self assert: FBSplitGateway isAbstract.
	self deny: FBExclusiveGateway isAbstract.
	self deny: FBMultiChoiceGateway isAbstract
]
