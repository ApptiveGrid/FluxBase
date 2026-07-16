Class {
	#name : 'FBActivationTest',
	#superclass : 'FBTest',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'as yet unclassified' }
FBActivationTest >> testChildTokenCarriesParentageAndScopeSplitBranchForward [
	| activation child |
	activation := FBActivation new.
	activation token
		scopeId: 'scope-1';
		splitId: 'split-1';
		branchId: 'branch-1'.
	child := activation childToken.
	self assert: child parentId equals: activation token id.
	self assert: child scopeId equals: 'scope-1'.
	self assert: child splitId equals: 'split-1'.
	self assert: child branchId equals: 'branch-1'.
	self deny: child id equals: activation token id
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
