"
I am one execution of a split: one pass of a running flow through an FBAndSplit or an
FBMultiChoiceGateway. The split's behavior opens me and hands me to every branch token
it creates (FBToken>>split); a child token inherits me (FBBaseActivation>>childToken), so
every strand of the pass carries me until it reaches the join.

I answer what the join needs to know and what the tokens alone cannot say:

	branchCount	how many branches this pass started - what the join waits for. The
			split knows this the moment it runs; the join's incoming transitions
			are only graph structure and do not know how many strands are
			actually on the way (two branches can share a predecessor, a
			condition can hold one back)
	outer		the split execution the split itself ran in, nil at the outermost
			level. The join gives its outgoing tokens this one back
			(FBJoinBehavior>>execute): behind the join the strand is a branch
			of the enclosing pass again, not of the one just joined. Without
			that an outer join kept the arrivals of two nested passes under two
			keys and never completed
	node		the split that opened me
	scope		the FBScope the pass runs in - what the FBJoinState made for me
			falls with (FBFlowInstance>>scopeEnded:)
	id		my identity for the outside: FBToken>>splitId and the event log
	origin		the token of the split's own activation - every branch's first token is
			a child of it (#branchOf:), which is how a deferred choice tells the
			winning branch from the rest (FBFlowInstance>>decideDeferredChoice:wonBy:)
	decided		for a deferred choice: whether one branch has gone on and the others
			fell; a later wait on the winner's way decides nothing more
	cancelledBranches
			how many of my branches were taken back and will never arrive
			(FBFlowInstance>>accountCancelledBranchesOf:). The join counts them
			as accounted for and goes on with what did arrive
			(FBJoinState>>canRelease); once every branch is gone and none
			arrived, the branch that led into me is gone for #outer too
			(FBFlowInstance>>settlePass:)

A split opens no scope: a scope answers 'what falls together', I answer 'who is expected
at the join' (see FBScope). FBFlowInstance keys each join's FBJoinState by me, so a
second pass through the same split - an iteration of a loop or of a parallel node -
gets a fresh state instead of inheriting the previous pass's arrivals.
"
Class {
	#name : 'FBSplitExecution',
	#superclass : 'Object',
	#instVars : [
		'id',
		'node',
		'outer',
		'branchCount',
		'scope',
		'cancelledBranches',
		'origin',
		'decided'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'instance creation' }
FBSplitExecution class >> openedBy: anActivation branchCount: anInteger [
	"the pass that anActivation - the split's own activation - starts: nested in the
	split execution and in the scope its token carries"
	^ self new
		node: anActivation node;
		origin: anActivation token;
		outer: anActivation token split;
		scope: anActivation token scope;
		branchCount: anInteger;
		yourself
]

{ #category : 'accessing' }
FBSplitExecution >> branchCount [
	^ branchCount
]

{ #category : 'accessing' }
FBSplitExecution >> branchCount: anInteger [
	branchCount := anInteger
]

{ #category : 'cancelling' }
FBSplitExecution >> branchCancelled [
	"one of my branches was taken back - its front token fell, see
	FBToken>>isFrontOfItsPass - and will never arrive at the join"
	cancelledBranches := cancelledBranches + 1
]

{ #category : 'accessing' }
FBSplitExecution >> cancelledBranches [
	^ cancelledBranches
]

{ #category : 'accessing' }
FBSplitExecution >> branchOf: aToken [
	"the first token of the branch aToken lies on - the child of #origin among its
	ancestors, aToken itself included - or nil when aToken does not descend from this
	pass's split at all"
	| current |
	current := aToken.
	[ current notNil and: [ current parent ~~ origin ] ] whileTrue: [ current := current parent ].
	^ current
]

{ #category : 'deciding' }
FBSplitExecution >> decide [
	decided := true
]

{ #category : 'testing' }
FBSplitExecution >> isDecided [
	^ decided == true
]

{ #category : 'accessing' }
FBSplitExecution >> origin [
	^ origin
]

{ #category : 'accessing' }
FBSplitExecution >> origin: aToken [
	origin := aToken
]

{ #category : 'accessing' }
FBSplitExecution >> id [
	^ id
]

{ #category : 'initialization' }
FBSplitExecution >> initialize [
	super initialize.
	id := FBIdGenerator current newId.
	cancelledBranches := 0.
	decided := false
]

{ #category : 'testing' }
FBSplitExecution >> isExhausted [
	"were all my branches taken back? Then nothing of this pass is on its way any more"
	^ cancelledBranches >= branchCount
]

{ #category : 'accessing' }
FBSplitExecution >> node [
	^ node
]

{ #category : 'accessing' }
FBSplitExecution >> node: aNode [
	node := aNode
]

{ #category : 'accessing' }
FBSplitExecution >> outer [
	^ outer
]

{ #category : 'accessing' }
FBSplitExecution >> outer: aSplitExecution [
	outer := aSplitExecution
]

{ #category : 'printing' }
FBSplitExecution >> printOn: aStream [
	super printOn: aStream.
	aStream nextPutAll: ' of '; print: node; nextPutAll: ', '; print: branchCount; nextPutAll: ' branches'
]

{ #category : 'accessing' }
FBSplitExecution >> scope [
	^ scope
]

{ #category : 'accessing' }
FBSplitExecution >> scope: aScope [
	scope := aScope
]
