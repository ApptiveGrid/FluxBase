Class {
	#name : 'FBMergeGatewayTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBMergeGatewayTest >> testMergeGatewayIsAbstractOnlyForTheBaseClass [
	self assert: FBMergeGateway isAbstract.
	self deny: FBSimpleMerge isAbstract
]

{ #category : 'tests' }
FBMergeGatewayTest >> testSimpleMergeIsAKindOfMergeGateway [
	self assert: (FBSimpleMerge inheritsFrom: FBMergeGateway)
]
