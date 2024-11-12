import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  gameApi: service(),
  flashMessages: service(),
  editEntry: null,
  selectedTemplate: null,
  add: true,
  editStack: null,
  editEntry: null,
  showEditEntry: false,
  entriesByTemplate: null,
  hasOptions: false,
  init() {
    this._super(...arguments);
    this.set('profileTabs', document.querySelector('[role=main]'));
    this.set(
      'classId',
      `collection-${this.collection?.toLowerCase().replace(/[ ]/, '-')}`,
    );

    const tabs = Object.entries(this.ledger?.stacks).map((e) => ({
      key: e[0],
      value: e[1].title || e[0][0].toUpperCase() + e[0].slice(1),
    }));
    this.set('tabs', tabs);

    const opts = {};
    const byTemplate = {};
    for (const [k, v] of Object.entries(this.ledger?.stacks)) {
      opts[k] = (v.lockable && v.lock) || v.delete || v.edit;
      byTemplate[k] = {};
      if (!v.templates) {
        byTemplate[k][k] = v.entries;
      } else {
        Object.keys(v.templates).forEach((t) => {
          byTemplate[k][t] = {};
          for (const [uuid, e] of Object.entries(v.entries)) {
            if (!byTemplate[k][e._template]) byTemplate[k][e._template] = {};
            byTemplate[k][e._template][uuid] = e;
          }
        });
      }
    }
    this.set('hasOptions', opts);
    this.set('entriesByTemplate', byTemplate);
  },
  didInsertElement() {
    this._super(...arguments);
    let tab = document.querySelectorAll('.profile-tab')[this.order || 1];
    if (!tab) tab = document.querySelector('.profile-tab');
    const ledger = document.querySelector(`#${this.classId}`);
    tab.after(ledger);
  },
  actions: {
    addEntry(stack, stackName, template = null) {
      this.set('editEntry', { _template: template, _stack: stackName });
      this.set('editStack', stack);
      this.set('stackName', stackName);
      this.set('add', true);
      this.set('showEditEntry', true);
    },
  },
});
