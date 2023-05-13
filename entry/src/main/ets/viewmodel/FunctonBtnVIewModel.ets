import BaseViewModel from './base/BaseViewModel';
import LogUtils from '../common/utils/LogUtils';
const TAG = 'FunctonBtnViewModel';

export default class FunctonBtnViewModel extends BaseViewModel{
  private static sFunctonBtnViewModel: FunctonBtnViewModel;
  public isMuted: boolean;
  public mMuteEnabledListener: (boolean) => void = (arg) => arg;
  public static getInstance(): FunctonBtnViewModel {
    if (!FunctonBtnViewModel.sFunctonBtnViewModel) {
      FunctonBtnViewModel.sFunctonBtnViewModel = new FunctonBtnViewModel();
    }
    return FunctonBtnViewModel.sFunctonBtnViewModel;
  }

 public setMuteEnabled(isMuted) {
     this.isMuted = isMuted;
 }
}