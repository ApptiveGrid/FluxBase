"
I run an FBTerminateEvent: mark my own step done and take every other strand of the
instance back. My own strand is not taken - it is the one that decided - so my
activation reads #done, and with nothing left the instance ends from
FBFlowInstance>>activateProtected: like any other run.
"
Class {
	#name : 'FBTerminateEventBehavior',
	#superclass : 'FBNodeBehavior',
	#category : 'FluxBase-Core-Behavior',
	#package : 'FluxBase-Core',
	#tag : 'Behavior'
}

{ #category : 'execution' }
FBTerminateEventBehavior >> execute [
	activation done.
	activation flowInstance terminateExcept: activation token
]
