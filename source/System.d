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
        m_id = id;
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
        foreach(obs; m_observers)
        {
            obs.onAdd(en);
        }
        return en;
    }
    /// Alive Entity.
    /// Params: An Entity.
    /// Returns: True if the Entity is alive. False, otherwise.
    bool alive(Entity en)
    {
        return lookup(en) != size_t.max;
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
    size_t lookup(Entity en) const
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
        foreach(obs; m_observers)
        {
            obs.onKill(en);
        }
        auto lastEntityId = m_entities[$-1].id();
        auto currIndex = lookup(en);
        if(m_entities.length == 1)
        {
            m_entities = m_entities[0..$-1]; // Workaround for [Issue 11576] New: std.algorithm.remove!(SwapStrategy.unstable) overruns array bounds
        }
        else
        {
            m_entities.remove!(SwapStrategy.unstable)(currIndex);
        }
        m_indices[lastEntityId]  = currIndex;
        m_indices[en.id()]       = size_t.max;
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
    bool empty() const
    {
        return length == 0;
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
    @property size_t length() const {
        return m_entities.length;
    }

    void attachObserver(Observer obs)
    {
        m_observers ~= obs;
    }
    unittest
    {
        class Dummy: Observer {
        public:
            void onAdd(Entity entity) { }
            void onKill(Entity enitity) { }
        }
        Dummy obs = new Dummy;
        System sys = new System;
        assert(sys.m_observers.length == 0);
        sys.attachObserver(obs);
        assert(sys.m_observers.length == 1);
    }

private:
    Entity[] m_entities;
    size_t[] m_indices;
    Observer[] m_observers;
}

interface Observer
{
    void onAdd(Entity entity);
    unittest
    {
        class Dummy: Observer {
        public:
            void onAdd(Entity entity) { added++; }
            int added = 0;
            void onKill(Entity enitity) { }
        }
        Dummy obs = new Dummy;
        System sys = new System;
        sys.attachObserver(obs);
        sys.add(); sys.add(); sys.add(); sys.add();
        assert(obs.added == 4);
    }
    void onKill(Entity entity);
    unittest
    {
        class Dummy: Observer {
        public:
            void onAdd(Entity entity) { overall++; }
            void onKill(Entity enitity) { overall--; }
            int overall = 0;
        }
        Dummy obs = new Dummy;
        System sys = new System;
        sys.attachObserver(obs);
        auto en0 = sys.add(); auto en1 = sys.add(); auto en2 = sys.add(); auto en3 = sys.add();
        assert(obs.overall == 4);
        sys.kill(en0);
        assert(obs.overall == 3);
        sys.kill(en1);
        assert(obs.overall == 2);
        sys.kill(en2);
        assert(obs.overall == 1);
        sys.kill(en3);
        assert(obs.overall == 0);
    }
}

class DoubleProperty: Observer
{
public:
    this(System sys)
    {
        sys.attachObserver(this);
        m_sys = sys;
    }
    void onAdd(Entity en)
    {
        m_values ~= 0.0;
    }
    void onKill(Entity en)
    {
        m_values.remove!(SwapStrategy.unstable)(m_sys.lookup(en));
    }
    double get(Entity en) const
    {
        return m_values[m_sys.lookup(en)];
    }
    unittest
    {
        System sys = new System;
        DoubleProperty prop = new DoubleProperty(sys);
        auto en = sys.add(); auto en2 = sys.add();
        prop.set(en, 1.2);
        prop.set(en2, 2.3);
        sys.kill(en);
        assert(prop.get(en2) == 2.3);
    }
    void set(Entity en, double value)
    {
        m_values[m_sys.lookup(en)] = value;
    }
    unittest
    {
        System sys = new System;
        DoubleProperty prop = new DoubleProperty(sys);
        auto en = sys.add();
        prop.set(en, 42.0);
        assert(prop.get(en) == 42.0);
    }

private:
    const System m_sys;
    double[] m_values;

}