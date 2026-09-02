Class {
	#name : 'FBActivationTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBActivationTest >> testChildTokenCarriesParentageAndScopeAndSplitForward [
	| activation child scope |
	scope := FBScope new.
	activation := FBActivation new.
	activation token
		scope: scope;
		splitId: 'split-1'.
	child := activation childToken.
	self assert: child parent equals: activation token.
	self assert: child scope equals: scope.
	self assert: child splitId equals: 'split-1'.
	self deny: child id equals: activation token id
]

{ #category : 'as yet unclassified' }
FBActivationTest >> testSourceNodeAnswersTheNodeTheActivationArrivedFrom [
	| start split a b join end flow instance arrivals |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance execute.
	arrivals := (instance activations select: [ :each | each node == join ])
		collect: [ :each | each sourceNode ].
	self assert: arrivals asSet equals: (Set with: a with: b)
]

{ #category : 'as yet unclassified' }
FBActivationTest >> testSourceNodeFallsBackToTheLegacyParentIdWhenThereIsNoParentReference [
	"Tokens persisted before FBToken>>parent became a real reference carry only the
	parent's id. Rebuild that state directly - the setters for it are gone on purpose -
	and check the old resolution path still answers the same node. Delete this together
	with FBToken>>parentId once no such tokens are left in any store."
	| start split a b join end flow instance arrival parentToken |
	start := FBStartEvent new.
	split := FBAndSplit named: 'split'.
	a := FBTask named: 'a'.
	b := FBTask named: 'b'.
	join := FBAndJoin named: 'join'.
	end := FBEndEvent new.
	start --> split.
	split --> a --> join.
	split --> b --> join.
	join --> end.
	flow := FBFlow new start: start.
	instance := flow newInstance.
	instance execute.
	arrival := (instance activations detect: [ :each | each node == join ]).
	parentToken := arrival token parent.
	arrival token
		instVarNamed: 'parent' put: nil;
		instVarNamed: 'parentId' put: parentToken id.
	self assert: arrival token parent isNil.
	self assert: arrival sourceNode equals: parentToken node
]

{ #category : 'as yet unclassified' }
FBActivationTest >> testSourceNodeIsNilWhenThereIsNeitherAParentNorALegacyId [
	self assert: FBActivation new sourceNode isNil
]

{ #category : 'tests' }
FBActivationTest >> testEnvironment [
	| activation node |
	node := FBTestTaskWithBehavior new.
	activation := FBActivation new.
	node activateWith: activation.
	self assert: (activation metadata at: #status) equals: '200'
]

{ #category : 'tests' }
FBActivationTest >> testEnvironmentSchema [
	| activation node |
	node := FBTestTaskWithBehavior new.
	activation := FBActivation new node: node.
	self assert: (activation metadataSchema at: #status) class equals: FBPropertyStringType 
]

{ #category : 'as yet unclassified' }
FBActivationTest >> testNewActivationHasAStableToken [
	| activation |
	activation := FBActivation new.
	self assert: activation token notNil.
	self assert: activation token id equals: activation token id
]

{ #category : 'as yet unclassified' }
FBActivationTest >> testTokenGetterDoesNotPersistDefaultForActivationsWithoutAStoredToken [
	| activation firstRead secondRead |
	activation := FBActivation new.
	activation token: nil.
	firstRead := activation token.
	secondRead := activation token.
	self assert: firstRead notNil.
	self assert: secondRead notNil.
	self deny: firstRead id equals: secondRead id
]
