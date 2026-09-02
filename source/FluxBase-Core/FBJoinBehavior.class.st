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
		splitId: activation token splitId.
	joinState arrived at: self arrivalKey put: self argument.
	activation done.
	"release once per FBJoinState. The condition is re-evaluated on every arrival, so
	without the latch a join whose #expected is already satisfied fires again for each
	further arrival - everything behind it would run a second time, with mail and
	external calls as side effects. An #expected of 1 with two branches feeding the
	join reaches this: the first arrival satisfies it and the second still finds it
	satisfied."
	joinState released ifTrue: [ ^ self ].
	(joinState arrived size >= joinState expected size) ifTrue: [
		joinState released: true.
		activation value: (self outputFrom: joinState).
		activation followAllOutgoing ]
]

{ #category : 'as yet unclassified' }
FBJoinBehavior >> outputFrom: aJoinState [
	"the join's own output reads as sourceNode -> value, which is what a following node
	can make sense of - PR #75 chose the node over the opaque branch identity for that
	reason. #arrived is keyed by token so the branches stay countable (see #arrivalKey),
	so re-key it here. Two branches that did arrive through the same predecessor collapse
	at this point, but by then the join has already seen both and released."
	| output |
	output := Dictionary new.
	aJoinState arrived keysAndValuesDo: [ :key :value |
		output at: (self sourceNodeOf: key) put: value ].
	^ output
]

{ #category : 'as yet unclassified' }
FBJoinBehavior >> sourceNodeOf: anArrivalKey [
	"#arrivalKey answers a token, or the node itself for tokens persisted without a
	real #parent"
	^ (anArrivalKey isKindOf: FBToken)
		ifTrue: [ anArrivalKey node ]
		ifFalse: [ anArrivalKey ]
]
