classdef AE_DimReductor < handle
    
   properties (SetAccess = immutable)
       TrainingSet = []; % set of data to train the AutoEncoder
       InputParams = []; % set of parameters fot the AutoEncoder setup
       Encoder = []; % the AutoEncoder
   end
   
   properties
       InputSet2Encode = []; % Set of data to be encoded
       InputSet2Decode = []; % Set of data to be decoded
       CodedSet = []; % set of encoded data (with shrinked dimension)
       SimulatedSet = []; % set of decoded data (same dimension of the InputSet)
       OUT4Debug = []; % for debugging and fine tuning purposes
   end
   
   methods
       
       function AE = AE_DimReductor(TrainingSet,params) % constructor
           
           AE.InputParams = params;
           AE.TrainingSet = TrainingSet;
           HiddenSize = AE.InputParams.HiddenSize;
           ETFun = AE.InputParams.EncoderTransferFunction;
           DTFun = AE.InputParams.DecoderTransferFunction;
           L2Reg = AE.InputParams.L2WeightRegularization;
           SpReg = AE.InputParams.SparsityRegularization;
           SpProp = AE.InputParams.SparsityProportion;
           MaxEpoch = AE.InputParams.MaxEpoch;
           Scale = AE.InputParams.ScaleData;
           
           AE.Encoder = trainAutoencoder(AE.TrainingSet, HiddenSize,...
               'EncoderTransferFunction',ETFun,...
               'DecoderTransferFunction', DTFun,...
               'L2WeightRegularization', L2Reg,...
               'SparsityRegularization', SpReg,...
               'SparsityProportion', SpProp,...
               'MaxEpochs', MaxEpoch,...
               'ShowProgressWindow',false,...
               'ScaleData', Scale);
            % 'UseGPU',true,...
       end
       
       function Encode(AE,InputSet)
           AE.InputSet2Encode = InputSet;
           AE.CodedSet = encode(AE.Encoder, AE.InputSet2Encode);
       end
       function Decode(AE,InputSet)
           AE.InputSet2Decode = InputSet;
           AE.SimulatedSet = decode(AE.Encoder, AE.InputSet2Decode);
       end
       
       
   end
end