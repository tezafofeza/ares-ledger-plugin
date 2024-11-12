import { helper } from '@ember/component/helper';

export function nl2br(params, hash) {
  return params[0].replace(/[\n]/g, '<br>');
}

export default helper(nl2br);
