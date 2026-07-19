Class {
	#name : 'FBWaitForCondition',
	#superclass : 'FBWait',
	#instVars : [
		'condition'
	],
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'testing' }
FBWaitForCondition class >> isAbstract [

	^ true
]

{ #category : 'accessing' }
FBWaitForCondition >> condition: aBlock [
	condition := aBlock 
]

{ #category : 'accessing' }
FBWaitForCondition >> defaultBehaviorClass [
	^ FBWaitForConditionBehavior 
]

{ #category : 'as yet unclassified' }
FBWaitForCondition >> evaluateConditionWith: anObject [
	^ condition value: anObject 
]
