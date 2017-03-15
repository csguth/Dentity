module system;

import std.algorithm;
import std.stdio;

/// An Entity
struct Entity
{
public:
    /// Entity id.
    /// Returns: the id of an entity.
    @property size_t id() const {
        return m_id;
    }
    ///
    unittest
    {
        const Entity en = Entity(42);
        assert(en.id == 42);
    }

private:
    this(size_t id)
    {
        this.m_id = id;
    }

    size_t m_id;
}

/// System class. Responsible for creating and destroying Entities.
class System
{
public:
    /// Add Entity
    /// Returns: The created entity.
    Entity add()
    {
        Entity en = Entity(m_indices.length);
        m_indices ~= m_entities.length;
        m_entities ~= en;
        return en;
    }
    /// Alive Entity.
    /// Params: An Entity.
    /// Returns: True if the Entity is alive. False, otherwise.
    bool alive(Entity en)
    {
        return lookup(en) != -1;
    }
    unittest
    {
        System a = new System;
        auto en = a.add();
        assert(a.length == 1);
        assert(a.alive(en));
    }
    /// Entity Lookup.
    /// Params: An Entity.
    /// Returns: The index of the Entity in the Entity's array.
    size_t lookup(Entity en)
    {
        return m_indices[en.id];
    }
    ///
    unittest
    {
        System a = new System;
        auto en = a.add();
        auto en2 = a.add();
        assert(a.lookup(en) == 0);
        assert(a.lookup(en2) == 1);
    }
    /// Kill Entity.
    /// Params: An Entity.
    void kill(Entity en)
    {
        m_indices[m_entities[$-1].id()] = lookup(en);
        m_entities = remove!(SwapStrategy.unstable)(m_entities, lookup(en));
        m_indices[en.id()] = -1;
    }
    /// System.alive usage after killing an Entity.
    unittest
    {
        System a = new System;
        auto en = a.add();
        a.kill(en);
        assert(!a.alive(en));
    }
    /// System.lookup usage after killing an Entity.
    unittest
    {
        System a = new System;
        auto en1 = a.add();
        auto en2 = a.add();
        a.kill(en1);
        assert(a.lookup(en2) == 0);
    }
    /// Empty
    /// Returns: True if there are no live Entities.
    bool empty()
    {
        return this.length == 0;
    }
    ///
    unittest
    {
        System  a = new System;
        assert(a.empty());
        auto en = a.add();
        assert(!a.empty());
        a.kill(en);
        assert(a.empty());
    }
    /// Length
    /// Returns: The number of live Entities.
    @property size_t length() {
        return m_entities.length;
    }

private:
    Entity[] m_entities;
    size_t[] m_indices;
}
