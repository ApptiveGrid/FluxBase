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

{ #category : 'tests' }
FBMergeGatewayTest >> testAllExposedNodeClassesHaveATypeName [
	"FBNode class>>exposedNodes (and #withType:) call #typeName on every
	exposed node class. FBAndJoin/FBOrJoin used to lack an override and
	would blow up with a doesNotUnderstand as soon as any code (e.g.
	AGFlowHolder sample flows, REST node-type listing) iterated over the
	full exposed set. exposedNodeClasses/exposedNodes/withType: themselves
	are ApptiveBase-Core extensions, not available when testing FluxBase
	standalone, so this reproduces the equivalent check using only
	FluxBase-Core primitives (allSubclasses/isAbstract/typeName)."

	(FBNode allSubclasses reject: #isAbstract) do: [ :each |
		self shouldnt: [ each typeName ] raise: MessageNotUnderstood ]
]
