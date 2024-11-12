import { computed } from '@ember/object';
import Component from './ledger-entry';

export default Component.extend({
  filteredFields: [],
  hasOptions: false,
  tableEntryDisplay: computed('entry', function () {
    const display = { ...this.entry };
    for (const [k, v] of Object.entries(display)) {
      if (v === true || v === false) display[k] = v ? 'Yes' : 'No';
      else display[k] = `${v}`;
    }
    return display;
  }),
  init() {
    this._super(...arguments);
    const list =
      (
        this.stack.fields[this.entry._stack] ||
        this.stack.fields[this.entry._template]
      )
        ?.filter((f) => {
          return this.tableFields?.includes(f.name);
        })
        ?.map((f) => (this.entry[`md_${f.key}`] ? `md_${f.key}` : f.key)) || [];
    this.set('filteredFields', list);
  },
});
