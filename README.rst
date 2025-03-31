==================================================================
How to manage major version transitions in the Virtual Observatory
==================================================================

:Date: 2025-03-10
:Authors:
  - Markus Demleitner
  - Brian Major
:Lang: en


.. contents::
  :class: toc
  :backlinks: none
  :local:

(This might become an IVOA note one day; for now, we keep the content in
the README as ReStructuredText.  Feel free to change directly or to do a
Pull Request; don't forget to add yourself to the authors).

Desiderata
----------

* Users should not see different VOs depending on which client they use
* Services should not be required to implement multiple major versions
* There cannot be flag days when all services must switch from version
  A to version B
* Clients should not be required to impement multiple major version
* A client written in year Y should not break because of our transition
  before year Y+N, where N is perhaps 5 or so

These desiderata are clearly conflicting.  If we want to strictly meet
all of them, we cannot have major version transitions.  It is the
purpose of this document to figure out where we compromise.

An important corollary to the realisation that we deal with severely
conflicting requirements is: major version transitions are always
painful.  Let's avoid them whenever we possibly can.


What is a breaking change?
--------------------------

DocStd is not very precise on what makes a major version:

  The [major version] number increments to 1 for the first public
  version, and to 2, 3, ..., for subsequent versions that are not
  backward compatible and/or require substantial revisions to
  implementations.

As a pragmatic, at least potentially testable definition, let me
propose: “A breaking change is one that, at least without careful
management, violates any of the desiderata above”.

In practice, there are several ways in which a revision of a standard
can impact interoperability (i.e., be “breaking”); in the following
examples, the old version is called A, the new version is called B:

* Version B requires a feature in a service that was not required in
  version A. Clients written against version B that use that feature
  will fail when querying a version A service.  Example: we could have
  required support for TIME and BAND in SIAP1; legacy services would
  have ignored the constraints, so the results are mildly wrong.  For
  standards rejecting unknown parameters, the services would be entirely
  broken.

* Version B stops requiring a feature (and has possibly
  replaced it by something
  else).  A version A client needing that feature will fail
  when querying a version B service.  Example: if we stopped requiring
  TAP_SCHEMA in TAP (which, incidentally, MD would very much like to
  do), clients expecting to get their column metadata from there will
  assume new services are broken and not let users inspect table
  metadata.

* Version B has a new standardID.  Clients of version A will not
  discover services for version B any more until an update, and
  depending on the client (or the version of the client) users will see
  different sets of services and hence a different VO.  Example: SIAP1
  clients will not see SIAP2 services; this is one of many problems
  when one wants to globally search images in today's VO (cf. `global
  data set discovery`_).

  .. _global   data set discovery: https://blog.g-vo.org/global-dataset-discovery-in-pyvo.html

* Version B modifies the behaviour of feature X.  Legacy clients break,
  sometimes predicatably, sometimes (apparently) randomly.  Example:
  Predictable failure on every document using binary serialisation (but:
  this *may* have looked random given that many services return
  TABLEDATA-serialised VOTables) *would* have happened if had we simply
  fixed VOTable's BINARY serialisation for sane NULL value handling in
  VOTable 1.3.  To be clear: This is not what happened; in actual
  history, instead we defined BINARY2 and only “mildly deprecated”
  BINARY\ [#notideal]_.

Exceptions
----------

Sometimes we can introduce breaking changes with impunity because we
*know* they do not *actually* break anything.  In this section, we look
at some examples for how we allow standard changes that *might* be
breaking to go forward nevertheless.

Removing Unused XSD Types in the Registry
'''''''''''''''''''''''''''''''''''''''''

A classic example is when
SimpleDALRegExt has defined a type ProtoSpectralAccess and we can see in
the Registry that nobody uses this type any more.  Hence, no publishing
registry will become invalid when we pull the type, and a change that
could technically be breaking will almost certainly not have bad
consequences.


Keeping Legacy Behaviour as a Fallback
''''''''''''''''''''''''''''''''''''''

Sometimes we may have “soft breakage”.  Consider an image service that
would like to offer cutouts.
It could, instead of returning FITS files, return datalink documents
with a SODA service
rather than FITSes. That service will appear completely broken to legacy
clients, which probably will show something like “broken image” for all
results.  That is hard breakage\ [#dlxslt]_.

If, on the other hand, that image service defined an associated datalink
service, declares that using a datalink service block with standardID
``ivo://ivoa.net/std/DataLink#links-1.1`` and otherwise keeps serving
FITSes, a datalink-enabled client can offer additional retrieval options
that a legacy client cannot, which arguably makes the VO “look
different”.  But at least the legacy clients still do what they were
expected to do when they were written (retrieve full images).  On the
other hand, because the service has to both hand out FITSes *and*
Datalinks, one might argue this is already in mild violation of our
“services should not have to implement two versions at the same tiime“
desideratum.


Evolving XML Schema While Keeping the Target Namespace
''''''''''''''''''''''''''''''''''''''''''''''''''''''

In the early days of the Virtual Observatory, XML namespace URIs were
written with minor versions in them (for instance,
``http://www.ivoa.net/xml/VOTable/v1.1`` for the original VOTable).
This made even minor version steps break all XML-conformant clients.
This mistake was repaired in an endorsed Note, `XML Schema Versioning
Policies`_.  The note in particular explains which kinds of changes are
legal while keeping the namespace URIs constant (i.e., „what is a
non-breaking change?“), which has certain impacts on how clients need to
be written.  The most important requirement here is that VO clients
parsing XML must ignore unknown elements to ensure that future
developments can add features.

.. _XML Schema Versioning Policies: https://ivoa.net/documents/Notes/XMLVers/

The XML versioning policies try hard not to break anything itself.  In
particular, the document froze the namespace
URIs whereever they were whan it was
adopted.  The consequence is that the XML schema version and the version
apparently implied from the namespace URI now disagree.  For instance,
``http://www.ivoa.net/xml/VOTable/v1.3`` is the namespace URI for
VOTable versions 1.3, 1.4, and 1.5 (and all further VOTable 1 versions).
While this keeps confusing implementors, it is at the same time an
example for the sort of pain one has to accept when maintaining
interoperability with systems that were designed in a suboptimal way –
and of how little errors made when authoring standards can explode
into huge problems when evolving technologies.


Evolving XML Schema While Keeping the Target Namespace
''''''''''''''''''''''''''''''''''''''''''''''''''''''

In the early days of the Virtual Observatory, XML namespace URIs were
written with minor versions in them (for instance,
``http://www.ivoa.net/xml/VOTable/v1.1`` for the original VOTable).
This made even minor version steps break all XML-conformant clients.
This mistake was repaired in an endorsed Note, `XML Schema Versioning
Policies`_.  The note in particular explains which kinds of changes are
legal while keeping the namespace URIs constant (i.e., „what is a
non-breaking change?“), which has certain impacts on how clients need to
be written.  The most important requirement here is that VO clients
parsing XML must ignore unknown elements to ensure that future
developments can add features.

.. _XML Schema Versioning Policies: https://ivoa.net/documents/Notes/XMLVers/

The XML versioning policies try hard not to break anything itself.  In
particular, it froze the namespace URIs whereever they were whan it was
adopted.  The consequence is that the XML schema version and the version
apparently implied from the namespace URI now disagree.  For instance,
``http://www.ivoa.net/xml/VOTable/v1.3`` is the namespace URI for
VOTable versions 1.3, 1.4, and 1.5 (and all further VOTable 1 versions).
While this keeps confusing implementors, this is at the same time an
example for the sort of pain one has to accept when maintaining
interoperability with systems that were designed in a suboptimal way –
and of how little errors made when authoring standards can explode
into huge problems when evolving technologies.


Case Study: Cone Search
-----------------------

There are several 10\ :sup:`4` Simple Cone Search (SCS) interfaces in
the Virtual Observatory.  SCS has been one of the first VO standards, and
it has several warts from today's perspective, such as:

(1) Error messaging is non-standard with respect to DALI
(2) It uses several ancient and (in the modern VO) invalid UCDs (e.g.,
    MAIN_ID) that are critical for the sensible interpretation of the results
(3) There is no way to discover additionally supported parameters *from
    the service*  (in principle, services can attach VOSI capability
    endpoints to the services and declare extra parameters in interface
    elements in there, but since the standard does not mention that,
    few services actually do that, and I don't think any clients make
    attempts to use anything like it).

Issue (3) could be fixed in a backwards-compatible way by requiring VOSI
capabilities in SCS 1.2 (or so); old clients would not know about the
extra parameters, new clients could show, for instance, extra query
fields.  The differences in appearance would probably be acceptable,
given that interfaces vary depending on the client anyway.

Issue (1) would only matter in case of failures, where legacy clients would
show generic, non-informative failures (“no data found” or perhaps
something resembling an HTTP-level
error if we also fix the “always return 200” policy of
current SCS), and only new clients would display useful error messages
generated by the VO interface.  I would suggest that might still count
as a soft failure.  Also (though I'd say that's acceptable), legacy
validators would flag new services as non-compliant.

Fixing issue (2) will probably break many clients that will not be able
to make sense of the results, i.e., deserialise them to lists of objects
with an ids and positions.  On the other hand, since we would use current
UCDs, many clients would still be able to do the right thing.

If we issue a SCS2, what would happen?

Without management, we will have SCS1 and SCS2 in parallel for an
unforseeable future; this is what we have with SIAP at the moment.

The consequence: some data collections will have SCS1 interfaces, others
SCS2, presumably many others both.  Legacy clients will not see SCS2 (so
the VO will look differently for them).  Modern clients will probably
see and use both.  This is not necessarily a large problem as long as
services produce just one resource record with one capability each for
each standard; it would be up to the client to hide the fact that there
are two interfaces on the same ressource.  Still, clients still doing
searches by service type plus keywords will have to modify their
registry interfaces in such a world.


Case Study: Response Serialisations
-----------------------------------

It has been suggested to modify VO protocols so that they return, say,
some form of JSON rather than VOTable.  There are various ways in which
such a change could be effected, which we briefly discuss below.

Each of the following cases assumes the pre-existence of a VO-JSON
standard that defines how to uniquely encode the content model of
VOTable (FIELDs, PARAMs, GROUPs, INFOs, etc) in JSON.  This VO-JSON
would then need to get some semi-blessed media type, presumably in DALI.

**(a)** issue a new minor version adding (or modifying) a DALI
RESPONSEFORMAT parameter to the protocol.  To keep the interface stable,
VOTable output must remain the default, but interested clients could
request VO-JSON explicitly after inspecting a service's minor version.
If VO-JSON has major advantages, it might eventually crowd out VOTable,
and we could perhaps one day switch the default and only have soft
breakage.  Advantage: Nothing breaks.  Disadvantage: it's a pain on both
clients and servers, both of which have to support both formats for an
indefinite time.  Also, the experience with VOTable BINARY2 (which *has*
clear advantages over BINARY) suggests that that wouldn't work.

**(b)** issue a new major version that switches the default to VO-JSON and
require that for a definite period, services implementing the new
version also provide an interfaces to the old.  Advantage: there is at
least a theoretical date at which the old standard vanishes.  For legacy
clients, nothing breaks until then.  New clients would probably still
support the old standard to avoid losing services, so the only advantage
over scenario (a) is that there is a theoretical date at which clients
only supporting the old version will stop working.

**(c)** issue a new major version and deprecate the old version.  *If*
data providers move along, legacy clients will see less and less of the
VO and new clients more and more (assuming they would not ignore the
deprecation, which the probably will not, at least initially).  It is
not unlikely that users of legacy clients (and, if still around, their
authors) would feel an increasing pressure to upgrade.  Advantage: It's
simple for (courageous, or those with *very* attractive data) service
operators.  Disadvantage: we will have a split VO at least until the
last legacy clients are phased out.  Also, the SIAP experience would
suggest that it will simply not work.  As of 2025, are still new SIAP1
services coming online, and SIAP2-only clients will miss out out quite a
few datasets out there.


Extra Traps
-----------

We have got some things wrong in the past that make transitions harder
now.  This section collects some of them.

Unversioned Standard ids
''''''''''''''''''''''''

In the registry, it was originally envisioned that standards would
be identified through the same string regardless of the version, and
different versions would be handled on the level of interfaces.  Based
on how actual clients were doing their discovery, it was
later decided that that was not a good idea and different major versions
should also have different standard ids.

However, by that time the standard ids of most of the protocols we are
using today were already defined.  And we told clients (for other
reasons) to do prefix matches on standard ids.  For instance, to look
for TAP services, you would use a constraint like::

  WHERE standard_id LIKE 'ivo://ivoa.net/std/tap%'

This is bad, because later on, when there are new major versions of TAP,
that will also match ``tap2``, ``tap3`` and so on, and hence legacy
clients will discover services they cannot talk to.

In the future, we should version-tag the identifiers from the start.
That is not immediately perfect, either, because the native pattern
above would then be::

  WHERE standard_id LIKE 'ivo://ivoa.net/std/tap1%'

and hence include ``tap10``, ``tap11``, etc, too.  Future standards,
sowever, will define features, and once they do that, the discovery
pattern will be a version-safe::

  WHERE standard_id LIKE 'ivo://ivoa.net/std/tap1#query-1.%'

or similar.  How we keep prefix-matching legacy clients from discoving
newer services without making their standard ids ugly, however, is still
unclear.


Conclusions
-----------

It is certainly a nasty problem.  We need to talk and scheme.

.. [#notideal] By the way, that hasn't worked too well either.  The
  golden rule of interoperability (“be strict in what you produce, be
  lenient in what you accept”) in that situation would suggest that as a
  server, you still return BINARY, which is what, for instance, DaCHS
  does to this day, 12 years after the publication of VOTable 1.3.

.. [#dlxslt] MD would like to would argue, though, that even that
  scenario can be turned into a “softer” breakage by at least making the
  datalink document usable in a browser, perhaps using xslt (cf.
  https://github.com/msdemlei/datalink-xslt); if the client displays the
  URI of the failing image, it is not unlikely that users would try
  their browser on it and then be at least able to manually retrieve the
  data set.
