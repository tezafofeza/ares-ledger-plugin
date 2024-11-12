import Component from '@ember/component';
import { inject as service } from '@ember/service';

export default Component.extend({
  gameApi: service(),
  editEntry: null,
  formEntry: null,
  didReceiveAttrs() {
    this._super(...arguments);
    this.set(
      'fields',
      this.stack?.fields[this.entry._template || this.entry._stack] || [],
    );
    this.set('templates', this.stack?.templates?.[this.entry._template]);
    this.set('formEntry', { ...this.entry });
  },
  clearForm() {
    this.set('showEditEntry', false);
    this.set('selectedTemplate', null);
    this.set('entry', {});
    this.set('formEntry', null);
  },
  actions: {
    addEntry() {
      this.gameApi
        .requestOne('addLedgerEntry', {
          char_id: this.char.id,
          collection: this.collection,
          template: this.formEntry._template,
          stack: this.stackName,
          entry: this.formEntry,
        })
        .then((res) => {
          if (res.error) return;
          this.clearForm();
          this.set(
            `entriesByTemplate.${res._stack}.${res._template}.${res.uuid}`,
            res,
          );
        });
    },
    updateEntry() {
      this.gameApi
        .requestOne('editLedgerEntry', {
          char_id: this.char.id,
          collection: this.collection,
          uuid: this.entry.uuid,
          edit: this.formEntry,
        })
        .then((res) => {
          if (res.error) return;
          this.clearForm();
          this.set(
            `entriesByTemplate.${res._stack}.${res._template}.${res.uuid}`,
            res,
          );
        });
    },
    updateEntryForm(field, event) {
      if (event.srcElement.type === 'checkbox') {
        this.set(`formEntry.${field}`, event.srcElement.checked);
      } else {
        this.set(`formEntry.${field}`, event.srcElement.value);
      }
    },
    updateTemplate(template) {
      this.set('selectedTemplate', template);
      template._template = this.entry._template;
      this.set('entry', template);
      this.set('formEntry', template);
    },
  },
});
