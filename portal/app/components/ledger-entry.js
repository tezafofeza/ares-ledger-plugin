import { computed } from '@ember/object';
import Component from '@ember/component';
import { inject as service } from '@ember/service';

const dtFormat = new Intl.DateTimeFormat('en', {
  timeStyle: 'medium',
  dateStyle: 'medium',
});

const getValue = (val) => {
  if (typeof val === 'boolean') return val ? 'Yes' : 'No';
  if (`${val}`.match(/^[+-]?\d+([.]\d+)?$/)) return val;
  return val;
};

export default Component.extend({
  tagName: '',
  gameApi: service(),
  add: false,
  exclude: [
    'created_at',
    'updated_at',
    'locked',
    'locked_on',
    'locked_by',
    'uuid',
    '_template',
    '_stack',
  ],
  init() {
    this._super(...arguments);
    if (this.stack.footnote) this.exclude.push(this.stack.footnote);

    const footnote = this.stack?.footnote?.map((f) => this.entry[f]).join(' ');
    this.set('footnote', footnote);
  },
  displayEntry: computed('entry', function () {
    if (!this.entry) return [];
    return Object.entries(this.entry)
      .map((e) => ({
        key: e[0],
        display: e[0].replace('_', ' '),
        value: this.entry[`md_${e[0]}`] || getValue(e[1]),
        md: this.entry[`md_${e[0]}`] !== undefined,
      }))
      .filter(
        (e) => !e.key.startsWith('md_') && !this.exclude.flat().includes(e.key),
      );
  }),
  locked_on: computed('entry.locked_on', function () {
    return dtFormat.format(new Date(this.entry.locked_on));
  }),
  actions: {
    editEntry() {
      this.set('editEntry', this.entry);
      this.set('editStack', this.stack);
      this.set('add', false);
      this.set('showEditEntry', true);
    },
    deleteEntry() {
      this.gameApi
        .requestOne('deleteLedgerEntry', {
          char_id: this.char.id,
          uuid: this.entry.uuid,
          collection: this.collection,
        })
        .then((res) => {
          if (res.error) return;
          this.set(
            `entriesByTemplate.${res._stack}.${res._template}.${res.uuid}`,
            null,
          );
        });
    },
    lockEntry() {
      this.gameApi
        .requestOne('lockLedgerEntry', {
          char_id: this.char.id,
          uuid: this.entry.uuid,
          collection: this.collection,
        })
        .then((res) => {
          if (res.error) return;
          this.set('entry', res);
        });
    },
    unlockEntry() {
      this.gameApi
        .requestOne('unlockLedgerEntry', {
          char_id: this.char.id,
          uuid: this.entry.uuid,
          collection: this.collection,
        })
        .then((res) => {
          if (res.error) return;
          this.set('entry', res);
        });
    },
  },
});
