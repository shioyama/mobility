---
id: intro
title: Introduction
slug: /
---

Mobility is a **framework** for **translating model data**. There are many
other gems out there that can help you store translated data[^1], but Mobility is
different. While other gems prescribe how to store your translations
and what features to offer for retrieving those translations, Mobility leaves
these choices up to you.

Mobility can do this thanks to a separation
between the **storage** of translation data ([backends](backends)) and the **use and manipulation** of
that data ([plugins](plugins)). This separation makes code cleaner, more powerful, and
easier to reuse.

These docs will guide you to integrating Mobility into your application and
provide some insights into the thinking behind its design. To get started right
away with Mobility, jump directly to the [Installation](installation) section.
For more background, read on.

## Why the name?

So first: why on _Earth_ is it called &#8220;Mobility&#8221;?

Mobility is a gem for translating content. The word &#8220;translation&#8221;
has multiple meanings:

> **translation** (_noun_):
> 1. a rendering from one language into another
> 2. uniform motion of a body in a straight line

Given that the term for these two meanings overlaps, it is perhaps not
surprising that many imagine translation to be a simple mapping
(along a straight line, if you will) of words from one language to another. In
reality, as any translator will tell you, translation is actually an incredibly
challenging and complex process.

The same can be said of _storing translations_, which can be more complicated
than one might think. Unfortunately, this only becomes apparent long after code
has been written and deployed. This commonly results in complex, fragile legacy
code coupled to a particular data format, with little room for change or
improvement.

> **mobility** (_noun_): the state of being movable or having the capacity to move

Mobility's purpose is to break this stranglehold on translation data and
give it the capacity to _move_. Similar to how Object Relational Mappers
(ORMs) create a separation between objects and their data, Mobility creates
a separation between the storage of translation data and the use of that data.

By doing so, translation features that are common across different applications
can be developed, shared and refined in isolation from the code used to store
those translations. This makes code easier to understand, modify, and improve.

## Minimalism

> I just want to translate these columns on this one model. I don't need
> a freaking framework for that!

This is an understandable gut reaction, but it is a misunderstanding of what
the word "framework" actually means.[^2] Mobility is built as a framework in
order to ensure that _you only include the code you need for your use case_. It is
a **minimalist framework**, and designed that way from the bottom up.

[^1]: [Globalize](https://github.com/globalize/globalize) and
[Traco](https://github.com/barsoom/traco) are two popular model translation
[^2]: See [this talk](https://www.youtube.com/watch?v=RZkemV_-__A) for more on this.
gems, but there are many more.
