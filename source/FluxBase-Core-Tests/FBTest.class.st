"
The base of every FluxBase-Core test. FBFlow class>>transitionClass is a class-side
variable, and ApptiveBase's tests set it to AGFlowTransition for their runs; their bases
set it back in #tearDown, but a run that was aborted, or a test base without that
teardown, leaves it standing - and every FluxBase test that builds a flow afterwards gets
ApptiveBase transitions and fails far from the cause. So every FluxBase test starts from
the default, whatever the image was left with.
"
Class {
	#name : 'FBTest',
	#superclass : 'TestCase',
	#category : 'FluxBase-Core-Tests',
	#package : 'FluxBase-Core-Tests'
}

{ #category : 'running' }
FBTest >> setUp [
	super setUp.
	FBFlow transitionClass: FBFlow defaultTransitionClass
]
