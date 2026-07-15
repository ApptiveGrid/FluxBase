Class {
	#name : 'FBCollectNodesVisitorTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'tests' }
FBCollectNodesVisitorTest >> testCollectsAllReachableNodesInABranchingFlow [
	| flow visitor |
	flow := FBFlow complex.
	visitor := FBCollectNodesVisitor new.
	visitor visit: flow.
	self assert: visitor nodes asSet equals: flow nodes asSet
]

{ #category : 'tests' }
FBCollectNodesVisitorTest >> testCollectsAllReachableNodesInASimpleFlow [
	| flow visitor |
	flow := FBFlow simpleFlow.
	visitor := FBCollectNodesVisitor new.
	visitor visit: flow.
	self assert: visitor nodes asSet equals: flow nodes asSet
]
