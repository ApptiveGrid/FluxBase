Class {
	#name : 'FBJoinBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'as yet unclassified' }
FBJoinBehavior >> arrivalKey [
	"the branch an arrival came through. The parent token identifies it, the source
	node does not: two branches of one split can reach the join through the same
	predecessor - one directly, the other after a detour - and would then collapse
	onto a single #arrived entry, so the join would never see all its branches.
	Tokens persisted before FBToken held a real #parent fall back to the node, which
	is what this used to key by all along."
	^ activation token parent ifNil: [ activation sourceNode ]
]

{ #category : 'as yet unclassified' }
FBJoinBehavior >> execute [
	| joinState |
	activation value: self argument.
	joinState := activation instance
		joinStateFor: activation node
		split: activation token split
		inScope: activation token scope.
	joinState arrived at: self arrivalKey put: self argument.
	joinState lastArrival: activation.
	activation done.
	"whether the join goes on, and once only, is the state's call (FBJoinState>>canRelease):
	it knows the branches that arrived and the ones taken back. A branch taken back after
	this arrival makes the state releasable from the withdrawal instead
	(FBFlowInstance>>settlePass:) - no further arrival would come to ask"
	joinState canRelease ifTrue: [ joinState releaseOn: activation instance executor ]
]
