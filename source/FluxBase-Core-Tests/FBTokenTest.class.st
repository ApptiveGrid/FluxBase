Class {
	#name : 'FBTokenTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBTokenTest >> testAccessorsRoundTrip [
	| token node |
	node := FBTask named: 't'.
	token := FBToken new.
	token
		node: node;
		value: 42;
		scopeId: 'scope-1';
		parentId: 'parent-1';
		splitId: 'split-1';
		branchId: 'branch-1';
		state: #waiting;
		metadata: #(1 2 3).
	self assert: token node equals: node.
	self assert: token value equals: 42.
	self assert: token scopeId equals: 'scope-1'.
	self assert: token parentId equals: 'parent-1'.
	self assert: token splitId equals: 'split-1'.
	self assert: token branchId equals: 'branch-1'.
	self assert: token state equals: #waiting.
	self assert: token metadata equals: #(1 2 3)
]

{ #category : 'as yet unclassified' }
FBTokenTest >> testNewTokenHasReadyStateAndUniqueId [
	| a b |
	a := FBToken new.
	b := FBToken new.
	self assert: a state equals: #ready.
	self assert: a id notNil.
	self deny: a id equals: b id
]
