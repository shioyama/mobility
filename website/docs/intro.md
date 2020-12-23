---
id: intro
title: Introduction
slug: /
---

Mobility is a **framework** for **translating model data**. There are many
other gems out there that can help you store translated data[^1], but Mobility is
different. While other gems prescribe _how_ to store your translations,
Mobility separates the **storage** of translation data from the **use and
manipulation** of translation data. This separation makes code cleaner, more
powerful, and easier to reuse.

These docs will guide you to integrating Mobility into your application and
provide some insights into the thinking behind its design. To get started right
away with Mobility, jump directly to the [Installation](installation) section.

## Why the name?

So first: why on Earth is it called "Mobility"?

The act of translation may seem simple, but ask any translator and you will
learn that it is in fact an incredibly challenging process.
The same
can be said of the process of _storing translations_. Unfortunately, this only
becomes apparent long after code has already been written and deployed. This
can result in complex legacy
code coupled to a particular data format, with little room for improvement.

Mobility's philosophy, similar to that of an Object Relational Mapper (ORM), is
to create a separation between the storage of data and the use (reading, writing,
and querying) of that data. By doing so, translation features that are common
across different applications can be developed, shared and refined in isolation
from the code used to store those translations. This makes code easier to change.

## Minimalism

> I just want to translate these columns on this one model. I don't need a freaking framework for that!

This is an understandable gut reaction, but it is a misunderstanding of what
the word "framework" actually means.[^2] Mobility is built as a framework in
order to ensure that _you only include the code you need for your use case_. It is
a **minimalist framework**, and designed that way from the bottom up.

[^1]: [Globalize](https://github.com/globalize/globalize) and
[Traco](https://github.com/barsoom/traco) are two popular model translation
[^2]: See [this talk](https://www.youtube.com/watch?v=RZkemV_-__A) for more on this.
gems, but there are many more.
