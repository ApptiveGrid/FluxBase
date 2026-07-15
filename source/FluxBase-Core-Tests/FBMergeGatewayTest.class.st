Class {
	#name : 'FBMergeGatewayTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBMergeGatewayTest >> testCannotHaveMoreThanOneOutgoingTransition [
	| merge a b |
	merge := FBSimpleMerge named: 'm'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	merge --> a.
	self
		should: [ merge --> b ]
		raise: FBCannotAddTransition
]

{ #category : 'tests' }
FBMergeGatewayTest >> testMergeGatewayIsAbstractOnlyForTheBaseClass [
	self assert: FBMergeGateway isAbstract.
	self deny: FBSimpleMerge isAbstract
]

{ #category : 'tests' }
FBMergeGatewayTest >> testSimpleMergeIsAKindOfMergeGateway [
	self assert: (FBSimpleMerge inheritsFrom: FBMergeGateway)
]
