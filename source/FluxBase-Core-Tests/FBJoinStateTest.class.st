Class {
	#name : 'FBJoinStateTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBJoinStateTest >> testAccessorsRoundTrip [
	| joinState node |
	node := FBTask named: 'join'.
	joinState := FBJoinState new.
	joinState
		joinNode: node;
		splitId: 'split-1';
		expected: (OrderedCollection with: 'a' with: 'b');
		arrived: (OrderedCollection with: 'a');
		released: true;
		policy: #all;
		scopeId: 'scope-1'.
	self assert: joinState joinNode equals: node.
	self assert: joinState splitId equals: 'split-1'.
	self assert: joinState expected equals: (OrderedCollection with: 'a' with: 'b').
	self assert: joinState arrived equals: (OrderedCollection with: 'a').
	self assert: joinState released.
	self assert: joinState policy equals: #all.
	self assert: joinState scopeId equals: 'scope-1'
]

{ #category : 'as yet unclassified' }
FBJoinStateTest >> testNewJoinStateHasEmptyExpectedAndArrivedAndIsNotReleased [
	| joinState |
	joinState := FBJoinState new.
	self assert: joinState expected isEmpty.
	self assert: joinState arrived isEmpty.
	self deny: joinState released
]
