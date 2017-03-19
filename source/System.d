module system;

import std.algorithm: remove, SwapStrategy;
import std.conv: to;
import std.signals;
import std.typecons: scoped;

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
    this()
    {
    }
    /// Add Entity
    /// Returns: The created entity.
    Entity add()
    {
        auto en     = Entity(m_indices.length);
        m_indices  ~= m_entities.length;
        m_entities ~= en;
        added.emit(en);
        return en;
    }
    /******************************
    * Alive Entity.
    * Params:
    *           en = A handler for an Entity.
    * Returns: True if the Entity is alive. False, otherwise.
    */
    bool alive(Entity en)
    {
        return lookup(en) != size_t.max;
    }
    ///
    unittest
    {
        System sys = new System;
        auto en = sys.add();
        assert(sys.alive(en));
        sys.kill(en);
        assert(!sys.alive(en));
    }
    /******************************
    * Entity lookup.
    * Params:
    *           en = A handler for an Entity.
    * Returns: The index of the Entity in the Entity's array.
    */
    size_t lookup(Entity en) const
    {
        return m_indices[en.id];
    }
    ///
    unittest
    {
        System sys = new System;
        auto en = sys.add();
        auto en2 = sys.add();
        assert(sys.lookup(en) == 0);
        assert(sys.lookup(en2) == 1);
    }
    /******************************
    * Kill Entity.
    * Params:
    *           en = A handler for an Entity.
    */
    void kill(Entity en)
    {
        killed.emit(en);
        auto lastEntityId        = m_entities[$-1].id();
        auto currIndex           = lookup(en);
        m_entities.remove!(SwapStrategy.unstable)(currIndex);
        --m_entities.length;
        m_indices[lastEntityId]  = currIndex;
        m_indices[en.id()]       = size_t.max;
    }
    /// System.alive usage after killing an Entity.
    unittest
    {
        System sys = new System;
        auto en = sys.add();
        sys.kill(en);
        assert(!sys.alive(en));
    }
    /// System.lookup usage after killing an Entity.
    unittest
    {
        System sys = new System;
        auto en1 = sys.add();
        auto en2 = sys.add();
        sys.kill(en1);
        assert(sys.lookup(en1) == size_t.max);
        assert(sys.lookup(en2) == 0);
        assert(sys.length == 1);
    }
    /******************************
    * Empty System.
    * Returns:
    *           True if there are no live Entities.
    */
    bool empty() const
    {
        return length == 0;
    }
    ///
    unittest
    {
        System sys = new System;
        assert(sys.empty());
        auto en = sys.add();
        auto en2 = sys.add();
        auto en3 = sys.add();
        assert(!sys.empty());
        sys.kill(en);
        sys.kill(en2);
        sys.kill(en3);
        assert(sys.empty());
    }
    /******************************
    * Length
    * Returns:
    *           The number of live Entities.
    */
    @property size_t length() const {
        return m_entities.length;
    }

    /******************************
    * Attach an Observer
    * Params:
    *           obs = The observer.
    */
    void attachObserver(Observer obs)
    {
        added.connect(&obs.onAdd);
        killed.connect(&obs.onKill);
    }
    /******************************
    * Dettach an Observer
    * Params:
    *           obs = The observer.
    */
    void detachObserver(Observer obs)
    {
        added.disconnect(&obs.onAdd);
        killed.disconnect(&obs.onKill);
    }
    ///
    unittest
    {
        class Dummy: Observer {
        public:
            void onAdd(Entity entity) { }
            void onKill(Entity enitity) { }
        }
        Dummy obs = new Dummy;
        System sys = new System;
        sys.attachObserver(obs);
        sys.detachObserver(obs);
    }
    override string toString()
    {
        return m_indices.to!string();
    }

private:
    size_t[] m_indices;
    Entity[] m_entities;
    mixin Signal!(Entity) added;
    mixin Signal!(Entity) killed;
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
        Dummy obs  = new Dummy;
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
        Dummy obs  = new Dummy;
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

/******************************
* Property
* Params:
*           T = The value type of the property.
*/
class Property(T): Observer
{
public:
    /******************************
    * Property Constructor
    * Params:
    *           sys = The Entity system this property should be attached to.
    */
    this(System sys)
    {
        sys.attachObserver(this);
        m_sys           = sys;
        m_values.length = sys.length;
    }
    ~this()
    {
        m_sys.detachObserver(this);
    }
protected:
    void onAdd(Entity en)
    {
        m_values ~= T();
    }
    void onKill(Entity en)
    {
        m_values.remove!(SwapStrategy.unstable)(m_sys.lookup(en));
        --m_values.length;
    }
public:
    /******************************
    * Property Getter
    * Params:
    *           en = A handler for an Entity.
    * Returns:
    *             T = The property.
    */
    T opIndex(Entity en) const
    {
        return m_values[m_sys.lookup(en)];
    }
    /******************************
    * Updates the property value for a given entity.
    * Params:
    *           en = A handler for an Entity.
    *        value = The value the property will be set to.
    * Returns:
    *             T = The property.
    */
    T opIndexAssign(T value, Entity en)
    {
        m_values[m_sys.lookup(en)] = value;
        return value;
    }
    override string toString()
    {
        return m_values.to!string();
    }

private:
    System m_sys;
       T[] m_values;

}
///
unittest
{
    System sys = new System;
    auto prop  = scoped!(Property!double)(sys);
    auto en    = sys.add();
    auto en2   = sys.add();
    prop[en]   = 1.2;
    prop[en2]  = 2.3;
    sys.kill(en);
    assert(prop[en2] == 2.3);
}
///
unittest
{
    System sys = new System;
    auto prop  = scoped!(Property!double)(sys);
    auto en    = sys.add();
    prop[en]   = 42.0;
    assert(prop[en] == 42.0);
}

///
unittest
{
    System sys = new System;
    auto en    = sys.add();
    auto prop  = scoped!(Property!int)(sys);
    prop[en]   = 42;
    assert(prop[en] == 42);
}