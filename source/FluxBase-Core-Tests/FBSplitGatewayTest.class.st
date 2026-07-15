Class {
	#name : 'FBSplitGatewayTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBSplitGatewayTest >> testSplitGatewayIsAbstractOnlyForTheBaseClass [
	self assert: FBSplitGateway isAbstract.
	self deny: FBExclusiveGateway isAbstract.
	self deny: FBMultiChoiceGateway isAbstract
]

{ #category : 'tests' }
FBSplitGatewayTest >> testExclusiveGatewayIsAKindOfSplitGateway [
	self assert: (FBExclusiveGateway inheritsFrom: FBSplitGateway)
]

{ #category : 'tests' }
FBSplitGatewayTest >> testMultiChoiceGatewayIsAKindOfSplitGateway [
	self assert: (FBMultiChoiceGateway inheritsFrom: FBSplitGateway)
]
