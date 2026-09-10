Class {
	#name : 'FBSubFlowNode',
	#superclass : 'FBNode',
	#instVars : [
		'subFlow',
		'maxDepth'
	],
	#category : 'FluxBase-Core',
	#package : 'FluxBase-Core'
}

{ #category : 'instance creation' }
FBSubFlowNode class >> typeName [
    ^ #subFlow
]

{ #category : 'accessing' }
FBSubFlowNode >> defaultBehaviorClass [
    ^ FBSubFlowBehavior
]

{ #category : 'accessing' }
FBSubFlowNode >> maxDepth [
    ^ maxDepth ifNil: [ FBScope defaultMaxDepth ]
]

{ #category : 'accessing' }
FBSubFlowNode >> maxDepth: anInteger [
    maxDepth := anInteger
]

{ #category : 'accessing' }
FBSubFlowNode >> subFlow [
    ^ subFlow
]

{ #category : 'accessing' }
FBSubFlowNode >> subFlow: aFBFlow [
    aFBFlow endNodes size = 1
        ifFalse: [ FBSubFlowInvalidTarget signal: 'sub flow must have exactly one end node, got ', aFBFlow endNodes size printString ].
    subFlow := aFBFlow
]

{ #category : 'testing' }
FBSubFlowNode >> opensCallScope [
	^ true
]

{ #category : 'testing' }
FBSubFlowNode >> parksOnEntry [
	"a call may take part in a deferred choice: its child usually waits - at a form, a
	remote flow - and a child that runs through decides the choice as it finishes
	(FBSubFlowExecutor>>finish), the way a condition that holds at once does"
	^ true
]
