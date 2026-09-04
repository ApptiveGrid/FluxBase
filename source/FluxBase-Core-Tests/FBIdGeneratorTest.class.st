Class {
	#name : 'FBIdGeneratorTest',
	#superclass : 'FBTest',
	#instVars : [
		'originalGenerator'
	],
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'running' }
FBIdGeneratorTest >> setUp [
	super setUp.
	originalGenerator := FBIdGenerator current
]

{ #category : 'running' }
FBIdGeneratorTest >> tearDown [
	FBIdGenerator current: originalGenerator.
	super tearDown
]

{ #category : 'tests' }
FBIdGeneratorTest >> testCurrentDefaultsToAUUIDGenerator [
	"The default is only observable when nothing has registered a generator yet. An
	integrated image (apptive-base) installs its own AGIdGenerator at load time, so the
	standalone condition has to be established here instead of assumed. setUp/tearDown
	keep and restore whatever the image had."

	FBIdGenerator current: nil.
	self assert: (FBIdGenerator current isKindOf: FBUUIDGenerator)
]

{ #category : 'tests' }
FBIdGeneratorTest >> testEnableSingletonSetsCurrent [
	| generator |
	generator := FBUUIDGenerator new.
	generator enableSingleton.
	self assert: FBIdGenerator current equals: generator
]

{ #category : 'tests' }
FBIdGeneratorTest >> testNewIdsAreUniqueStrings [
	| ids |
	ids := (1 to: 100) collect: [ :each | FBIdGenerator current newId ].
	self assert: (ids allSatisfy: [ :each | each isString ]).
	self assert: ids asSet size equals: 100
]
