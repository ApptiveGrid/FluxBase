"
I am the bookkeeping for one join node waiting on one execution of one split.

FBFlowInstance keeps me under the key { joinNode. split } - see
#joinStateFor:split:inScope: - so every pass through a split gets its own instance of
me. That is what keeps a loop from inheriting the previous pass's arrivals and
releasing the join immediately.

	joinNode	the join I belong to
	split		the FBSplitExecution - the pass through the split - I belong to (see
			FBToken>>split); nil for arrivals on tokens persisted before splits
			were objects
	expected	one slot per branch that has to arrive before the join may proceed -
			as many as the split started (FBSplitExecution>>branchCount), or the
			join's incoming transitions where there is no split to ask
	arrived		branch -> value for the branches that already did, keyed by the
			token an arrival came through (FBJoinBehavior>>arrivalKey). Two
			branches of one split can share a predecessor node, so the node
			cannot tell them apart while the token can. The join's own output
			is re-keyed to sourceNode -> value on release, which is the shape
			a following node can read (#output).
	released	guard against releasing the same join twice
	lastArrival	the join's activation of the latest arrival - the one that goes on
			behind the join when I release, within its own step or later, from a
			withdrawal that made me releasable (FBFlowInstance>>settlePass:)
	scope		the FBScope the split execution I belong to ran in - an iteration of
			a parallel node, a sub flow call, or the instance's root. What lets me
			fall with that scope instead of with the whole instance
			(FBFlowInstance>>scopeEnded:)
"
Class {
	#name : 'FBJoinState',
	#superclass : 'Object',
	#instVars : [
		'joinNode',
		'split',
		'expected',
		'arrived',
		'released',
		'scope',
		'lastArrival'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'as yet unclassified' }
FBJoinState >> arrived [
	^ arrived
]

{ #category : 'as yet unclassified' }
FBJoinState >> arrived: aCollection [
	arrived := aCollection
]

{ #category : 'as yet unclassified' }
FBJoinState >> expected [
	^ expected
]

{ #category : 'as yet unclassified' }
FBJoinState >> expected: aCollection [
	expected := aCollection
]

{ #category : 'as yet unclassified' }
FBJoinState >> initialize [
	super initialize.
	expected := OrderedCollection new.
	arrived := Dictionary new.
	released := false
]

{ #category : 'as yet unclassified' }
FBJoinState >> joinNode [
	^ joinNode
]

{ #category : 'as yet unclassified' }
FBJoinState >> joinNode: aFBNode [
	joinNode := aFBNode
]

{ #category : 'as yet unclassified' }
FBJoinState >> released [
	^ released
]

{ #category : 'as yet unclassified' }
FBJoinState >> released: aBoolean [
	released := aBoolean
]

{ #category : 'accessing' }
FBJoinState >> split [
	^ split
]

{ #category : 'accessing' }
FBJoinState >> split: aSplitExecution [
	split := aSplitExecution
]

{ #category : 'accessing' }
FBJoinState >> splitId [
	"the pass by id, for the outside"
	^ split ifNotNil: [ :each | each id ]
]

{ #category : 'accessing' }
FBJoinState >> scope [
	^ scope
]

{ #category : 'accessing' }
FBJoinState >> scope: aScope [
	scope := aScope
]

{ #category : 'accessing' }
FBJoinState >> lastArrival [
	^ lastArrival
]

{ #category : 'accessing' }
FBJoinState >> lastArrival: anActivation [
	lastArrival := anActivation
]

{ #category : 'testing' }
FBJoinState >> canRelease [
	"may the join go on now? Once, and when every branch of the pass is accounted for:
	arrived, or taken back and never coming (FBSplitExecution>>cancelledBranches) - and
	at least one arrived to go on with. A pass whose branches all fell releases
	nothing; the join never ran for it, and the enclosing pass loses a branch instead
	(FBFlowInstance>>settlePass:). Without a pass - arrivals on tokens persisted before
	splits were objects - every expected slot has to arrive.

	The latch: the condition holds for every arrival after the releasing one too, and
	without it a join whose count is met fires again for each - everything behind it
	would run a second time, with mail and external calls as side effects"
	released ifTrue: [ ^ false ].
	arrived isEmpty ifTrue: [ ^ false ].
	^ arrived size + (split ifNil: [ 0 ] ifNotNil: [ :each | each cancelledBranches ]) >= expected size
]

{ #category : 'releasing' }
FBJoinState >> releaseOn: anExecutor [
	"go on behind the join: the last arrival's activation gets my output as its value
	and follows the join's outgoing on anExecutor, on tokens of the enclosing pass - the
	pass just joined is closed. Within a step anExecutor is the one running
	(FBJoinBehavior>>execute); from a withdrawal it is the executor that ran the
	arrival, where the join stands - not whatever frame is on top of the instance at
	that moment (FBFlowInstance>>settlePass:)"
	released := true.
	lastArrival value: self output.
	lastArrival followAllOutgoingInSplit: (split ifNotNil: [ :each | each outer ]) on: anExecutor
]

{ #category : 'accessing' }
FBJoinState >> output [
	"the join's own output reads as sourceNode -> value, which is what a following node
	can make sense of - PR #75 chose the node over the opaque branch identity for that
	reason. #arrived is keyed by token so the branches stay countable (see
	FBJoinBehavior>>arrivalKey), so re-key it here. Two branches that did arrive through
	the same predecessor collapse at this point, but by then the join has already seen
	both. A branch taken back is not in here: the join goes on with what arrived"
	| output |
	output := Dictionary new.
	arrived keysAndValuesDo: [ :key :value |
		output at: (self sourceNodeOf: key) put: value ].
	^ output
]

{ #category : 'private' }
FBJoinState >> sourceNodeOf: anArrivalKey [
	"FBJoinBehavior>>arrivalKey answers a token, or the node itself for tokens
	persisted without a real #parent"
	^ (anArrivalKey isKindOf: FBToken)
		ifTrue: [ anArrivalKey node ]
		ifFalse: [ anArrivalKey ]
]
