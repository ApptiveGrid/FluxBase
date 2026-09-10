Class {
	#name : 'FBJoinStateTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBJoinStateTest >> testAccessorsRoundTrip [
	| joinState node scope split |
	node := FBTask named: 'join'.
	scope := FBScope rootOwnedBy: nil.
	split := FBSplitExecution new.
	joinState := FBJoinState new.
	joinState
		joinNode: node;
		split: split;
		expected: (OrderedCollection with: 'a' with: 'b');
		arrived: (OrderedCollection with: 'a');
		released: true;
		scope: scope.
	self assert: joinState joinNode equals: node.
	self assert: joinState split identicalTo: split.
	self assert: joinState splitId equals: split id.
	self assert: joinState expected equals: (OrderedCollection with: 'a' with: 'b').
	self assert: joinState arrived equals: (OrderedCollection with: 'a').
	self assert: joinState released.
	self assert: joinState scope identicalTo: scope
]

{ #category : 'as yet unclassified' }
FBJoinStateTest >> testNewJoinStateHasEmptyExpectedAndArrivedAndIsNotReleased [
	| joinState |
	joinState := FBJoinState new.
	self assert: joinState expected isEmpty.
	self assert: joinState arrived isEmpty.
	self deny: joinState released
]
