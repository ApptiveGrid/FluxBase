Class {
	#name : 'FBJoinBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'as yet unclassified' }
FBJoinBehavior >> execute [
	| joinState |
	activation value: self argument.
	joinState := activation instance
		joinStateFor: activation node
		splitId: activation token splitId.
	"key each arrival by the node it came from, so the branches stay distinguishable
	and the join's own output reads as sourceNode -> value"
	joinState arrived at: activation sourceNode put: self argument.
	activation done.
	"release once per FBJoinState. The condition is re-evaluated on every arrival, so
	without the latch a join whose #expected is already satisfied fires again for each
	further arrival - everything behind it would run a second time, with mail and
	external calls as side effects. Two branches arriving through the same predecessor
	are the case that reaches this: they collapse onto one #arrived entry, so the
	second arrival still sees the condition hold."
	joinState released ifTrue: [ ^ self ].
	(joinState arrived size >= joinState expected size) ifTrue: [
		joinState released: true.
		activation value: joinState arrived.
		activation followAllOutgoing ]
]
