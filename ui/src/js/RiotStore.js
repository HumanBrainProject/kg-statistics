/*
*   Copyright (c) 2018, EPFL/Human Brain Project PCO
*
*   Licensed under the Apache License, Version 2.0 (the "License");
*   you may not use this file except in compliance with the License.
*   You may obtain a copy of the License at
*
*       http://www.apache.org/licenses/LICENSE-2.0
*
*   Unless required by applicable law or agreed to in writing, software
*   distributed under the License is distributed on an "AS IS" BASIS,
*   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
*   See the License for the specific language governing permissions and
*   limitations under the License.
*/

class RiotStore {

    constructor(name, states, init, reset){
        var self = this;
        this.name = name;
        this.states = {};
        this.actions = {};
        this.interfaces = {
            is:function(name){
                return self.is(name);
            }
        };
        this.lifeCycle = {
            init:init,
            reset:reset
        };

        states.forEach(name => this.states[name] = false);
    }

    init(initOptions){
        this.lifeCycle.init(initOptions);
    }

    reset(){
        this.lifeCycle.reset();
    }

    notifyChange(options){
        RiotPolice.trigger(this.name+".changed", options);
    }

    failStateExists(name){
        if(this.states[name] === undefined){
            throw "Trying to access a state that has not been defined";
        }
    }

    addState(name){
        if(this.states[name] === undefined){
            this.states[name] = false;
        }
    }

    removeState(name){
        if(this.states[name] !== undefined){
            delete this.states[name];
        }
    }

    toggleState(name, state){
        this.failStateExists(name);
        this.states[name] = (state !== undefined)? !!state: !this.states[name];
    }

    clearStates(){
        Object.keys(this.states).forEach(name => this.states[name] = false);
    }

    is(name){
        this.failStateExists(name);
        return this.states[name];
    }

    addAction(name, action){
        this.actions[name] = action;
    }

    addInterface(name, cb){
        this.interfaces[name] = cb;
    }

}