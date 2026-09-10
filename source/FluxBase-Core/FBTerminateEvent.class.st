"
I end the whole instance the moment I am reached, whatever else is still running or
waiting in it: Explicit Termination (WCP-43). An FBEndEvent ends its own strand and
leaves the others to finish; I take the others back (FBFlowInstance>>terminateExcept:)
and the instance ends as #done - a modelled end, not a cancellation, so the root scope
stays as it is and the instance does not read #cancelled. What was taken back reads so:
the tokens, and the activations that stood on a wait.

Not an FBEndEvent: FBFlow>>end and #endNodes are about the end that carries the result,
and a sub flow must have exactly one of those. I am a terminal node of my own kind.

Abstract in the sense of the exposed node set only, until ApptiveGrid can show me;
instantiable all the same.
"
Class {
	#name : 'FBTerminateEvent',
	#superclass : 'FBEvent',
	#category : 'FluxBase-Core-Model',
	#package : 'FluxBase-Core',
	#tag : 'Model'
}

{ #category : 'testing' }
FBTerminateEvent class >> isAbstract [
	"see the class comment"
	^ true
]

{ #category : 'instance creation' }
FBTerminateEvent class >> typeName [
	^ #terminate
]

{ #category : 'adding' }
FBTerminateEvent >> addOutgoing: aTransition [ 
	FBCannotAddTransition signal: 'a terminate node cannot have outgoing transitions'
]

{ #category : 'accessing' }
FBTerminateEvent >> defaultBehaviorClass [
	^ FBTerminateEventBehavior
]

{ #category : 'initialization' }
FBTerminateEvent >> initialize [
	super initialize.
	name := 'terminate'
]

{ #category : 'testing' }
FBTerminateEvent >> isFlowTerminal [
	^ true
]
