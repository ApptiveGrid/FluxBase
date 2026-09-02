"
I am the bookkeeping for one join node waiting on one execution of one split.

FBFlowInstance keeps me under the key { joinNode. splitId } - see
#joinStateFor:splitId: - so every pass through a split gets its own instance of
me. That is what keeps a loop from inheriting the previous pass's arrivals and
releasing the join immediately.

	joinNode	the join I belong to
	splitId		which split execution I belong to (see FBToken>>splitId)
	expected	the branches that have to arrive before the join may proceed
	arrived		branch -> value for the branches that already did, keyed by the
			token an arrival came through (FBJoinBehavior>>arrivalKey). Two
			branches of one split can share a predecessor node, so the node
			cannot tell them apart while the token can. The join's own output
			is re-keyed to sourceNode -> value on release, which is the shape
			a following node can read (FBJoinBehavior>>outputFrom:).
	released	guard against releasing the same join twice
"
Class {
	#name : 'FBJoinState',
	#superclass : 'Object',
	#instVars : [
		'joinNode',
		'splitId',
		'expected',
		'arrived',
		'released',
		'scopeId'
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

{ #category : 'as yet unclassified' }
FBJoinState >> scopeId [
	^ scopeId
]

{ #category : 'as yet unclassified' }
FBJoinState >> scopeId: anObject [
	scopeId := anObject
]

{ #category : 'as yet unclassified' }
FBJoinState >> splitId [
	^ splitId
]

{ #category : 'as yet unclassified' }
FBJoinState >> splitId: anObject [
	splitId := anObject
]
