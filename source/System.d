module System;

import std.stdio;
import std.algorithm;

class Entity
{
private:
    this(ulong id)
    {
        this.m_id = id;
    }
public:
    @property ulong id() { return m_id; }
    unittest
    {
        auto en = new Entity(42);
        assert(en.id == 42);
    }
    @property bool valid() { return m_valid; }
    unittest
    {
        auto en = new Entity(42);
        assert(en.valid);
    }
private:
    void die() { m_valid = false; }
    unittest
    {
        auto en = new Entity(42);
        en.die();
        assert(!en.valid);
    }
    ulong m_id;
    bool m_valid = true;
}

/// System class. Responsible for creating and destroying Entities.
class System
{
public:
    Entity add()
    {
        auto entity = new Entity(m_indices.length);
        m_indices ~= m_entities.length;
        m_entities ~= entity;
        return entity;
    }
    bool valid(Entity en)
    {
        return en.valid;
    }
    unittest
    {
        System a = new System;
        auto en = a.add();
        assert(a.length == 1);
        assert(a.valid(en));
    }
    ulong lookup(Entity en)
    {
        return m_indices[en.id];
    }
    unittest
    {
        System a = new System;
        auto en = a.add();
        auto en2 = a.add();
        assert(a.lookup(en) == 0);
        assert(a.lookup(en2) == 1);
    }
    void erase(Entity en)
    {
        en.die();
        m_entities = remove!(SwapStrategy.unstable)(m_entities, lookup(en));
    }
    unittest
    {
        System a = new System;
        auto en = a.add();
        a.erase(en);
        assert(!a.valid(en));
        assert(a.empty());
        auto en2 = a.add();
        auto en3 = a.add();
        assert(a.length == 2);
        a.erase(en2);
        assert(a.length == 1);
        assert(!a.valid(en));
        assert(!a.valid(en2));
        assert(a.valid(en3));
    }
    /// Empty
    bool empty()
    {
        return this.length == 0;
    }
    ///
    unittest
    {
        System a = new System;
        assert(a.empty());
        auto en = a.add();
        assert(!a.empty());
        a.erase(en);
        assert(a.empty());
    }

    /// length
    @property ulong length() { return m_entities.length; }

private:
    Entity[] m_entities;
    ulong[] m_indices;
}